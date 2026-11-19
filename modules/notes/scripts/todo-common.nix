{ pkgs }:

# Packages a shared Python module as an importable library so
# `todo` and `todo-list` (see todo.nix / todo-list.nix) can share
# it via writePython3Bin's `libraries` instead of each carrying its
# own copy of the same helpers.
let
  todoCommonSrc = pkgs.writeText "todo_common.py" ''
    """Shared helpers for the `todo` and `todo-list` scripts (see
    todo.nix / todo-list.nix).
    """

    import os
    import re
    import sys
    import shlex
    import calendar
    import curses
    import datetime
    import subprocess

    # Configuration for output formatting, shared by both scripts.
    INDENT_UNIT = "    "

    # Target marker in a journal file (if found, new todos are inserted
    # right after this line instead of at the end of the file).
    TODO_MARKER = "%%insert_todo%%"

    # Checklist state characters (the content of "[ ]").
    VALID_STATES = {
        " ": "open",
        "x": "done",
        "i": "event",
        "/": "in-progress",
        "-": "cancelled",
        "<": "delegated",
        ">": "forwarded",
    }

    # Obsidian Tasks plugin priority emoji, highest to lowest.
    PRIORITY_SYMBOLS = [
        ("\U0001F53A", "highest"),  # 🔺
        ("\u23EB", "high"),         # ⏫
        ("\U0001F53C", "medium"),   # 🔼
        ("\U0001F53D", "low"),      # 🔽
        ("\u23EC", "lowest"),       # ⏬
    ]

    # -p/--priority and inline "<-p N>" accept 1 (highest) .. 5
    # (lowest), mapped onto PRIORITY_SYMBOLS in that order.
    PRIORITY_EMOJI = {
        i + 1: emoji for i, (emoji, _name) in enumerate(PRIORITY_SYMBOLS)
    }


    def normalize_state(value):
        """Lowercase and validate a checklist state value (-s/--state,
        CLI or inline). Returns the normalized single-character state,
        or raises ValueError with a usable message.
        """
        state = value.lower()
        if len(state) != 1 or state not in VALID_STATES:
            valid = ", ".join(f"{s!r}" for s in VALID_STATES)
            raise ValueError(f"invalid state {value!r}; expected one of: {valid}")
        return state


    def normalize_priority(value):
        """Validate a priority value (-p/--priority, inline only - the
        CLI uses argparse's choices= instead). Returns the priority
        as an int, or raises ValueError with a usable message.
        """
        try:
            priority = int(value)
        except ValueError:
            raise ValueError("value must be an integer")
        if priority not in PRIORITY_EMOJI:
            valid = ", ".join(str(p) for p in sorted(PRIORITY_EMOJI))
            raise ValueError(f"value must be one of: {valid}")
        return priority


    def _parse_inline_int(value):
        try:
            return int(value)
        except ValueError:
            raise ValueError("value must be an integer")


    # Single source of truth for every flag shared between the CLI
    # (`todo`'s and `todo-list`'s argparse parsers) and the "<...>"
    # inline syntax (see parse_inline_options) - add a flag here once
    # and it's available, with the same spelling/types/validation, in
    # both, rather than keeping two hand-written, driftable copies in
    # sync. "argparse" holds the kwargs passed to parser.add_argument
    # (besides the flag strings themselves); callers may override/add
    # to these via add_shared_arguments's **overrides. "parse" is the
    # inline-value parser (value string -> options[dest]), or None for
    # a plain store_true flag.
    SHARED_FLAGS = [
        dict(
            dest="today", short="-t", long="--today", parse=None,
            argparse=dict(action="store_true", help="Set to today."),
        ),
        dict(
            dest="tomorrow", short="-T", long="--tomorrow", parse=None,
            argparse=dict(action="store_true", help="Set to tomorrow."),
        ),
        dict(
            dest="offset", short="-o", long="--offset",
            parse=_parse_inline_int,
            argparse=dict(
                type=int, default=0,
                help=(
                    "Offset in days from today (or weeks, with "
                    "-w/--weekly). Positive for future, negative for "
                    "past."
                ),
            ),
        ),
        dict(
            dest="date", short="-d", long="--date", parse=lambda v: v,
            argparse=dict(
                type=str,
                help=(
                    "Set to a specific date. Accepts a weekday name "
                    "(e.g. 'friday', 'fri', optionally prefixed with "
                    "'next'), 'today', 'tomorrow', 'yesterday', or a "
                    "YYYY-MM-DD date. The date may be partial - "
                    "MM-DD (current year) or DD (current year and "
                    "month) - and the missing parts are filled in."
                ),
            ),
        ),
        dict(
            dest="calendar", short="-c", long="--calendar", parse=None,
            argparse=dict(
                action="store_true",
                help=(
                    "Interactively pick the date from a calendar "
                    "(weeks start on Monday). Overrides -d/--date, "
                    "-o/--offset, -T/--tomorrow and -t/--today."
                ),
            ),
        ),
        dict(
            dest="weekly", short="-w", long="--weekly", parse=None,
            argparse=dict(
                action="store_true",
                help=(
                    "Target the weekly journal (JOURNAL_WEEKLY_PATH) "
                    "instead of the daily one. -o/--offset is "
                    "interpreted in weeks rather than days."
                ),
            ),
        ),
        dict(
            dest="file", short="-f", long="--file", parse=lambda v: v,
            argparse=dict(
                type=str, nargs="?",
                help=(
                    "Target a specific markdown file directly. If "
                    "given with no argument, pick the file "
                    "interactively with fzf from $NOTES_DIR (not "
                    "supported inline - a path must be given)."
                ),
            ),
        ),
        dict(
            dest="state", short="-s", long="--state",
            parse=normalize_state,
            argparse=dict(
                type=str, default=None,
                help=(
                    "Checklist state - the character to put inside "
                    "\"[ ]\": " + ", ".join(
                        f"{s!r} ({name})"
                        for s, name in VALID_STATES.items()
                    ) + "."
                ),
            ),
        ),
        dict(
            dest="priority", short="-p", long="--priority",
            parse=normalize_priority,
            argparse=dict(
                type=int, default=None, choices=sorted(PRIORITY_EMOJI),
                help=(
                    "Priority, written as an Obsidian Tasks priority "
                    "emoji: 1 (highest) through "
                    f"{max(PRIORITY_EMOJI)} (lowest)."
                ),
            ),
        ),
    ]

    _SHARED_FLAGS_BY_DEST = {spec["dest"]: spec for spec in SHARED_FLAGS}
    _SHARED_FLAGS_BY_TOKEN = {
        tok: spec
        for spec in SHARED_FLAGS
        for tok in (spec["short"], spec["long"])
    }


    def add_shared_arguments(parser, include, **overrides):
        """Add argparse arguments for the given SHARED_FLAGS dests (in
        the given order) to parser - the same flags, spellings and
        validation as the "<...>" inline syntax (see
        parse_inline_options), so CLI and inline can't drift apart.
        overrides maps dest -> extra/overridden add_argument kwargs
        (e.g. a script-specific help string, or 'const').
        """
        for dest in include:
            spec = _SHARED_FLAGS_BY_DEST[dest]
            kwargs = dict(spec["argparse"])
            kwargs.update(overrides.get(dest, {}))
            parser.add_argument(spec["short"], spec["long"], **kwargs)


    def parse_prefixed_line(stripped):
        """Parse leading nesting/description markers off an input line.

        Each level of nesting is marked by a "-" character, e.g.
        "- foo" is a sub-todo and "- - foo" (equivalently "--foo" or
        any mix of spacing, like "- -foo") is a sub-sub-todo. A "."
        right after the nesting markers turns the line into a
        description/note attached to the item at that depth instead
        of a new item, e.g. ". note" is a note on the last
        top-level item and "- . note" (or "-. note", "-.note", ...)
        is a note on the last sub-todo. Whitespace around the
        markers is optional and ignored; the returned content is
        always trimmed of surrounding whitespace.

        Returns (depth, is_desc, content).
        """
        match = re.match(r"^((?:-\s*)*)(\.)?\s*(.*)$", stripped)
        markers, dot, content = match.groups()
        depth = markers.count("-")
        is_desc = dot is not None
        return depth, is_desc, content.strip()


    def format_output_line(depth, is_desc, content, mark=" "):
        if is_desc:
            indent = INDENT_UNIT * (depth + 1)
            return f"{indent}- {content}"
        indent = INDENT_UNIT * depth
        return f"{indent}- [{mark}] {content}"


    def select_file_with_fzf():
        notes_dir = os.getenv("NOTES_DIR")
        if not notes_dir:
            print("Error: NOTES_DIR not set.", file=sys.stderr)
            sys.exit(1)

        try:
            # Use fd to get list of files, then pipe to sort, then to fzf
            fd_cmd = [
                "fd", "--type", "f", "--extension", "md",
                "--absolute-path", ".", notes_dir
            ]
            sort_cmd = ["sort"]
            fzf_cmd = ["fzf", "--prompt=Select file: ", "--no-sort"]

            p1 = subprocess.Popen(fd_cmd, stdout=subprocess.PIPE)
            p2 = subprocess.Popen(
                sort_cmd, stdin=p1.stdout, stdout=subprocess.PIPE
            )
            p1.stdout.close()
            p3 = subprocess.Popen(
                fzf_cmd, stdin=p2.stdout, stdout=subprocess.PIPE
            )
            p2.stdout.close()

            stdout, _ = p3.communicate()
            if p3.returncode == 0:
                return stdout.decode().strip()
            else:
                print("Selection cancelled.", file=sys.stderr)
                sys.exit(0)
        except FileNotFoundError:
            print("Error: fzf or fd not found in PATH.", file=sys.stderr)
            sys.exit(1)


    # Calendar weekday abbreviations, Monday first (like `cal --monday`)
    WEEKDAY_HEADER = "Mo Tu We Th Fr Sa Su"


    def add_months(date, delta):
        """Return date shifted by delta months, clamping the day."""
        month_index = date.month - 1 + delta
        year = date.year + month_index // 12
        month = month_index % 12 + 1
        day = min(date.day, calendar.monthrange(year, month)[1])
        return date.replace(year=year, month=month, day=day)


    def draw_calendar(stdscr, cursor_date):
        stdscr.erase()
        cal = calendar.Calendar(firstweekday=0)  # Monday first
        weeks = cal.monthdayscalendar(cursor_date.year, cursor_date.month)
        today = datetime.date.today()

        header = cursor_date.strftime("%B %Y")
        stdscr.addstr(0, 0, header.center(len(WEEKDAY_HEADER)),
                      curses.A_BOLD)
        stdscr.addstr(1, 0, WEEKDAY_HEADER, curses.A_UNDERLINE)

        row = 2
        for week in weeks:
            col = 0
            for day in week:
                text = f"{day:2d}" if day else "  "
                attr = curses.A_NORMAL
                if day:
                    day_date = cursor_date.replace(day=day)
                    if day_date == cursor_date:
                        attr = curses.A_REVERSE
                    elif day_date == today:
                        attr |= curses.A_BOLD
                stdscr.addstr(row, col, text, attr)
                col += 3
            row += 1

        help_text = (
            "hjkl/arrows: move  n/p: month  t: today  "
            "enter: select  q: cancel"
        )
        stdscr.addstr(row + 1, 0, help_text)
        stdscr.refresh()


    def run_calendar(initial_date=None):
        """Show an interactive calendar and return the selected date.

        Returns a ``datetime.date`` for the selected day, or ``None``
        if the user cancelled.
        """

        def _inner(stdscr):
            curses.curs_set(0)
            stdscr.keypad(True)
            cursor_date = initial_date or datetime.date.today()

            while True:
                draw_calendar(stdscr, cursor_date)
                key = stdscr.getch()

                if key in (curses.KEY_LEFT, ord("h")):
                    cursor_date -= datetime.timedelta(days=1)
                elif key in (curses.KEY_RIGHT, ord("l")):
                    cursor_date += datetime.timedelta(days=1)
                elif key in (curses.KEY_UP, ord("k")):
                    cursor_date -= datetime.timedelta(days=7)
                elif key in (curses.KEY_DOWN, ord("j")):
                    cursor_date += datetime.timedelta(days=7)
                elif key in (ord("p"), curses.KEY_PPAGE):
                    cursor_date = add_months(cursor_date, -1)
                elif key in (ord("n"), curses.KEY_NPAGE):
                    cursor_date = add_months(cursor_date, 1)
                elif key == ord("t"):
                    cursor_date = datetime.date.today()
                elif key in (ord("\n"), curses.KEY_ENTER, ord(" ")):
                    return cursor_date
                elif key in (27, ord("q")):
                    return None

        return curses.wrapper(_inner)


    def pick_calendar_date():
        """Run the interactive calendar and return the picked date.

        Exits the program if the user cancels.
        """
        selected = run_calendar(datetime.date.today())
        if selected is None:
            print("No date selected.", file=sys.stderr)
            sys.exit(1)
        return selected


    def parse_date(date_str):
        date_str = date_str.lower().strip()
        today = datetime.date.today()

        if date_str == "today":
            return today
        if date_str == "tomorrow":
            return today + datetime.timedelta(days=1)
        if date_str == "yesterday":
            return today - datetime.timedelta(days=1)

        weekdays = {
            'monday': 0, 'mon': 0,
            'tuesday': 1, 'tue': 1,
            'wednesday': 2, 'wed': 2,
            'thursday': 3, 'thu': 3,
            'friday': 4, 'fri': 4,
            'saturday': 5, 'sat': 5,
            'sunday': 6, 'sun': 6
        }

        # Handle "next [weekday]"
        is_next = False
        if date_str.startswith("next "):
            is_next = True
            date_str = date_str[5:].strip()

        if date_str in weekdays:
            target_wd = weekdays[date_str]
            days_ahead = (target_wd - today.weekday()) % 7
            if is_next:
                days_ahead += 7
            return today + datetime.timedelta(days=days_ahead)

        # Fallback to a (possibly partial) YYYY-MM-DD date. Missing
        # leading components are filled in with the current year
        # and/or month, e.g. "DD" or "MM-DD".
        parts = date_str.split("-")
        if len(parts) == 3:
            year, month, day = parts
            if len(year) != 4:
                raise ValueError("year must be four digits")
        elif len(parts) == 2:
            year = str(today.year)
            month, day = parts
        elif len(parts) == 1:
            year = str(today.year)
            month = str(today.month)
            day = parts[0]
        else:
            raise ValueError("too many components")
        return datetime.datetime.strptime(
            f"{year}-{month}-{day}", "%Y-%m-%d"
        ).date()


    def parse_inline_options(content):
        """Pull a leading "<...>" block of todo flags off content.

        Lets a single multi-line interactive `todo` entry, or --tui's
        a/e keys in `todo-list`, carry a date/state/target on the
        typed text itself instead of it being swallowed as part of
        the title, or shared by every line, e.g. "<-T> Buy milk"
        alongside "<-t> Call bank". Recognizes -d/--date, -o/--offset,
        -t/--today, -T/--tomorrow, -c/--calendar, -s/--state,
        -p/--priority, -w/--weekly and -f/--file - same meaning/
        accepted values as both scripts' matching command-line flags.
        The block, if present, must be the very first thing in
        content (callers run this after stripping any "-"/"." nesting
        markers via parse_prefixed_line) - its contents are
        shlex-split, so shell-style quoting works (e.g.
        "<-d 'next friday'>"), and a long option may bundle its
        value with "=" same as argparse (e.g. "<--state=i>").

        As at the command line, -c overrides -d/-o/-T/-t, and
        -f overrides -w.

        Using -f/--file or -w/--weekly on content that is not a new
        top-level todo (a sub-todo or note) has no effect - only a
        new top-level line can redirect which file a block lands in.
        A bare, fzf-driven "-f" (no value) is not supported inline; a
        path must be given.

        Returns (options, remaining_content); options is {} if there
        is no "<...>" block. Raises ValueError (with a usable
        message) on an unterminated "<", an unknown flag, a missing
        value, or an invalid value.
        """
        stripped = content.lstrip()
        if not stripped.startswith("<"):
            return {}, content

        end = stripped.find(">")
        if end == -1:
            raise ValueError("unterminated '<' in inline options")
        raw, rest = stripped[1:end], stripped[end + 1:].lstrip()

        try:
            tokens = shlex.split(raw)
        except ValueError as e:
            raise ValueError(f"invalid inline options {raw!r}: {e}")

        options = {}
        i = 0
        while i < len(tokens):
            tok = tokens[i]
            # As with argparse, a long option may bundle its value
            # with "=", e.g. "--state=i".
            inline_value = None
            if tok.startswith("--") and "=" in tok:
                tok, inline_value = tok.split("=", 1)
            spec = _SHARED_FLAGS_BY_TOKEN.get(tok)
            if spec is None:
                raise ValueError(f"unknown inline option {tok!r}")
            if spec["parse"] is None:
                if inline_value is not None:
                    raise ValueError(f"{tok} takes no value")
                options[spec["dest"]] = True
                i += 1
                continue
            if inline_value is None:
                if i + 1 >= len(tokens):
                    raise ValueError(f"{tok} needs a value")
                inline_value = tokens[i + 1]
                i += 2
            else:
                i += 1
            try:
                options[spec["dest"]] = spec["parse"](inline_value)
            except ValueError as e:
                raise ValueError(f"{tok} {e}")
        return options, rest


    def resolve_inline_due_date(options):
        """Resolve a "YYYY-MM-DD" due date from a parsed inline-options
        dict, using the same flag precedence as the command-line date
        flags (-c > -d > -o > -T > -t). -o/--offset is interpreted in
        weeks rather than days if -w/--weekly is also set, same as
        the command-line flags. Returns None if none of calendar/
        date/offset/tomorrow/today was given.
        """
        today = datetime.date.today()
        if options.get("calendar"):
            return pick_calendar_date().strftime("%Y-%m-%d")
        if "date" in options:
            return parse_date(options["date"]).strftime("%Y-%m-%d")
        if "offset" in options:
            delta = (
                datetime.timedelta(weeks=options["offset"])
                if options.get("weekly")
                else datetime.timedelta(days=options["offset"])
            )
            return (today + delta).strftime("%Y-%m-%d")
        if options.get("tomorrow"):
            return (today + datetime.timedelta(days=1)).strftime("%Y-%m-%d")
        if options.get("today"):
            return today.strftime("%Y-%m-%d")
        return None


    def resolve_inline_file(options, due):
        """Resolve a direct file-path override implied by -f/--file
        or -w/--weekly in a parsed inline-options dict, to use instead
        of resolve_due_date_file's usual daily-journal redirect.
        -f takes precedence over -w if both are given. due is the
        already-resolved due date (see resolve_inline_due_date), used
        to pick which week -w lands in; today's week is used if due
        is None.

        Returns None if neither -f nor -w was given. Raises
        ValueError if -w/--weekly is given but JOURNAL_WEEKLY_PATH
        isn't set.
        """
        if "file" in options:
            return options["file"]
        if not options.get("weekly"):
            return None
        weekly_path = os.getenv("JOURNAL_WEEKLY_PATH")
        if not weekly_path:
            raise ValueError("JOURNAL_WEEKLY_PATH not set")
        target_date = parse_date(due) if due else datetime.date.today()
        iso_year, iso_week, _ = target_date.isocalendar()
        return os.path.join(weekly_path, f"{iso_year}-W{iso_week:02d}.md")


    def resolve_due_date_file(due, fallback_path):
        """Return the daily journal file a \U0001F4C5 due date should
        land in: that date's own file if it exists (or the date is
        today), else today's file. Returns fallback_path unchanged if
        JOURNAL_DAILY_PATH isn't set (e.g. -f/--file, -w/--weekly, or
        --all contexts with no daily journal to redirect into).
        """
        journal_dir = os.getenv("JOURNAL_DAILY_PATH")
        if not journal_dir:
            return fallback_path
        today_str = datetime.date.today().strftime("%Y-%m-%d")
        assigned_file = os.path.join(journal_dir, f"{due}.md")
        if due == today_str or os.path.exists(assigned_file):
            return assigned_file
        return os.path.join(journal_dir, f"{today_str}.md")


    def apply_inline_options(content, is_desc):
        """Fold a leading "<...>" inline-options block (see
        parse_inline_options) out of content and into the shape
        callers expect: an explicit -p/--priority is appended as its
        Obsidian Tasks priority emoji (unless content already carries
        one), a resolved due date is appended after that as a
        \U0001F4C5 emoji tag (unless content already carries one, in
        which case it's left alone), and an explicit -s/--state
        becomes the returned mark character.

        Returns (content, mark, due, file); mark is None if no
        -s/--state was given (callers should leave the existing/
        default mark alone in that case, rather than stomping it with
        " "); due is the resolved "YYYY-MM-DD" date, or None if no
        calendar/date/offset/today/tomorrow flag was given - pass it
        to resolve_due_date_file() to find which file the todo should
        actually land in; file is a direct file-path override from
        -f/--file or -w/--weekly (see resolve_inline_file), or None if
        neither was given, in which case callers should fall back to
        resolve_due_date_file() (or their own default) as usual.
        Raises ValueError if content carries inline options but
        is_desc (notes have no state/due/priority/file semantics), or
        if the options themselves fail to parse (see
        parse_inline_options) or resolve (see resolve_inline_file).
        """
        options, content = parse_inline_options(content)
        if not options:
            return content, None, None, None
        if is_desc:
            raise ValueError("inline options aren't supported on notes")
        if "priority" in options and not any(
            e in content for e in PRIORITY_EMOJI.values()
        ):
            content = f"{content} {PRIORITY_EMOJI[options['priority']]}"
        due = resolve_inline_due_date(options)
        if due and "\U0001F4C5" not in content:
            content = f"{content} \U0001F4C5 {due}"
        file = resolve_inline_file(options, due)
        return content, options.get("state"), due, file
  '';
in
pkgs.python3Packages.buildPythonPackage {
  pname = "todo-common";
  version = "0.1.0";
  format = "other";
  src = todoCommonSrc;
  dontUnpack = true;
  doCheck = false;

  installPhase = ''
    mkdir -p $out/${pkgs.python3.sitePackages}
    cp ${todoCommonSrc} $out/${pkgs.python3.sitePackages}/todo_common.py
  '';
}
