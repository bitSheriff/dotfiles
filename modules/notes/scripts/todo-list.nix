{ pkgs }:

pkgs.writers.writePython3Bin "todo-list" { } ''
    import os
    import re
    import sys
    import calendar
    import curses
    import datetime
    import argparse
    import subprocess

    # Configuration for output formatting (matches the `todo` script)
    INDENT_UNIT = "    "

    # Marker the `todo` command inserts new todos after (see todo.nix).
    # Used by -O/--open to jump straight to the todo section.
    TODO_MARKER = "%%insert_todo%%"

    DEFAULT_EDITOR = "nvim"

    USE_COLOR = sys.stdout.isatty()


    def c(code, s):
        return f"\033[{code}m{s}\033[0m" if USE_COLOR else s


    # Obsidian Tasks plugin emoji signifiers (default "Tasks Emoji
    # Format"). See the "Tasks Emoji Format" page in the Tasks plugin
    # docs (publish.obsidian.md/tasks). There is no mature Python
    # library that implements this format, so it is parsed here
    # directly - it's a small, well-documented spec.
    TASK_DATE_FIELDS = [
        ("due", "\U0001F4C5"),         # 📅
        ("scheduled", "\u23F3"),       # ⏳
        ("start", "\U0001F6EB"),       # 🛫
        ("created", "\u2795"),         # ➕
        ("done", "\u2705"),            # ✅
        ("cancelled", "\u274C"),       # ❌
    ]

    TASK_PRIORITY_SYMBOLS = [
        ("\U0001F53A", "highest"),  # 🔺
        ("\u23EB", "high"),         # ⏫
        ("\U0001F53C", "medium"),   # 🔼
        ("\U0001F53D", "low"),      # 🔽
        ("\u23EC", "lowest"),       # ⏬
    ]

    TASK_RECURRENCE_SYMBOL = "\U0001F501"  # 🔁

    TASK_FIELD_DISPLAY_ORDER = [
        "due", "scheduled", "start", "created", "done", "cancelled",
        "priority", "recurrence",
    ]


    def extract_task_metadata(text):
        """Strip Obsidian Tasks plugin emoji signifiers off a todo line.

        Recognizes due/scheduled/start/created/done/cancelled dates
        (\U0001F4C5 \u23F3 \U0001F6EB \u2795 \u2705 \u274C, each followed
        by a YYYY-MM-DD date), priority
        (\U0001F53A \u23EB \U0001F53C \U0001F53D \u23EC), and recurrence
        (\U0001F501 followed by a free-text rule, e.g. "every week").

        Returns (clean_text, metadata) where metadata maps field name
        ("due", "priority", "recurrence", ...) to its string value.
        """
        remaining = text
        meta = {}

        for name, emoji in TASK_DATE_FIELDS:
            m = re.search(
                re.escape(emoji) + r"\s*(\d{4}-\d{2}-\d{2})", remaining
            )
            if m:
                meta[name] = m.group(1)
                remaining = remaining[:m.start()] + remaining[m.end():]

        for emoji, name in TASK_PRIORITY_SYMBOLS:
            if emoji in remaining:
                meta["priority"] = name
                remaining = remaining.replace(emoji, "")
                break

        m = re.search(re.escape(TASK_RECURRENCE_SYMBOL) + r"\s*(.+)$", remaining)
        if m:
            meta["recurrence"] = m.group(1).strip()
            remaining = remaining[:m.start()]

        return remaining.strip(), meta


    def format_task_metadata(meta):
        if not meta:
            return ""
        parts = []
        for field in TASK_FIELD_DISPLAY_ORDER:
            if field not in meta:
                continue
            if field == "due" and meta.get("due_implied"):
                # Implicit due dates (every open todo in a daily journal
                # defaults to that day) aren't worth displaying - they're
                # true for virtually every todo and add no information.
                continue
            parts.append(f"{field} {meta[field]}")
        return " (" + ", ".join(parts) + ")" if parts else ""


    DAILY_FILENAME_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})\.md$")


    def infer_journal_date(path):
        """Return the date encoded in a daily journal filename.

        Daily journal files are named "YYYY-MM-DD.md" (see `jour`/
        `todo`). Returns a date object, or None if the filename
        doesn't match that pattern (e.g. weekly journals, regular
        notes).
        """
        m = DAILY_FILENAME_RE.match(os.path.basename(path))
        if not m:
            return None
        try:
            return datetime.datetime.strptime(
                m.group(1), "%Y-%m-%d"
            ).date()
        except ValueError:
            return None


    def apply_implicit_due_dates(nodes, date_str):
        """Default every todo without an explicit due date to date_str.

        In a daily journal, a todo with no \U0001F4C5 due date is
        implicitly due on that journal's own day. Mutates nodes
        in place (recursing into sub-todos) and marks defaulted
        entries with meta["due_implied"] = True so display/filtering
        can tell them apart from an explicit due date. Calendar
        events ("- [i] ...") are skipped - they aren't "due" on any
        particular day, they're always shown.
        """
        for n in nodes:
            if not n.get("is_event") and "due" not in n["meta"]:
                n["meta"]["due"] = date_str
                n["meta"]["due_implied"] = True
            apply_implicit_due_dates(n["children"], date_str)


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


    def parse_journal_todos(path):
        """Parse a journal file into a tree of todo nodes.

        Mirrors the format written by the `todo` command: checklist
        lines ("- [ ] ..." / "- [x] ...") nested by INDENT_UNIT-sized
        indentation, with plain "- ..." bullet lines one level
        deeper treated as notes attached to the nearest enclosing
        todo at that depth. Unrelated markdown (headings, prose,
        bullets with no enclosing todo at the right depth) is
        ignored. Obsidian Tasks plugin emoji metadata (dates,
        priority, recurrence) embedded in a todo's text is parsed
        out via extract_task_metadata() and stored separately.
        "- [i] ..." lines are calendar events and "- [/] ..." lines
        are in-progress todos - neither is ever considered "done",
        and both are always kept regardless of --done/--today
        filtering (see filter_tree/filter_due_today). "- [-] ..."
        lines are cancelled todos - they count as "done" (hidden
        unless --done is passed) but are rendered distinctly.

        Returns a list of top-level nodes, each
        {"text", "done", "is_event", "in_progress", "cancelled",
        "meta": {...}, "notes": [...], "children": [...]}.
        """
        if not os.path.exists(path):
            return []

        with open(path) as f:
            lines = f.readlines()

        checklist_re = re.compile(
            r"^(?P<indent>\s*)-\s*\[(?P<mark>[ xXiI/-])\]\s*(?P<text>.*)$"
        )
        note_re = re.compile(r"^(?P<indent>\s*)-\s+(?P<text>.*)$")

        roots = []
        stack = {}  # depth -> node, for the todos currently "open" above us

        for raw in lines:
            line = raw.rstrip("\n")
            if not line.strip():
                # A blank line ends the current contiguous todo block - a
                # note/sub-todo only belongs to a todo if it's on a line
                # directly below it (same scope, no gaps), so any open
                # parents are no longer eligible to receive children/notes.
                stack = {}
                continue

            m = checklist_re.match(line)
            if m:
                depth = len(m.group("indent")) // len(INDENT_UNIT)
                text, meta = extract_task_metadata(m.group("text").strip())
                mark = m.group("mark").lower()
                node = {
                    "text": text,
                    "done": mark in ("x", "-"),
                    "is_event": mark == "i",
                    "in_progress": mark == "/",
                    "cancelled": mark == "-",
                    "meta": meta,
                    "notes": [],
                    "children": [],
                }
                for d in [d for d in stack if d >= depth]:
                    del stack[d]
                parent = stack.get(depth - 1)
                if parent is not None:
                    parent["children"].append(node)
                else:
                    roots.append(node)
                stack[depth] = node
                continue

            m = note_re.match(line)
            if m:
                note_depth = len(m.group("indent")) // len(INDENT_UNIT)
                parent = stack.get(note_depth - 1)
                if parent is not None:
                    parent["notes"].append(m.group("text").strip())
                continue

            # Any other non-blank line (heading, prose, unrelated bullet
            # list, ...) also ends the current contiguous todo block, for
            # the same reason as a blank line above.
            stack = {}

        return roots


    def filter_tree(nodes, show_done):
        if show_done:
            return nodes
        result = []
        for n in nodes:
            if n["done"] and not n.get("is_event"):
                continue
            n = dict(n)
            n["children"] = filter_tree(n["children"], show_done)
            result.append(n)
        return result


    def filter_due_today(nodes, today_str):
        """Keep not-done todos due today or overdue, plus their ancestors.

        A todo matches if it isn't done and its due date is today or
        earlier (ISO YYYY-MM-DD strings sort chronologically, so a
        plain string comparison is enough - overdue todos are
        meant to get done today too). Ancestors of a matching todo
        are kept (without being considered matches themselves)
        purely to preserve context; todos/branches with no matching
        descendant are dropped. Calendar events ("- [i] ...") and
        in-progress todos ("- [/] ...") always match, regardless of
        their due date.
        """
        result = []
        for n in nodes:
            due = n.get("meta", {}).get("due")
            matches = n.get("is_event") or n.get("in_progress") or (
                not n["done"] and due is not None and due <= today_str
            )
            kept_children = filter_due_today(n["children"], today_str)
            if matches or kept_children:
                n = dict(n)
                n["children"] = kept_children
                result.append(n)
        return result


    def find_marker_line(path, marker):
        """Return the 1-indexed line number of the first line
        containing marker, or None if the file doesn't exist or
        doesn't contain it.
        """
        if not os.path.exists(path):
            return None
        with open(path) as f:
            for i, line in enumerate(f, start=1):
                if marker in line:
                    return i
        return None


    def open_in_editor(path, editor=DEFAULT_EDITOR):
        """Open path in editor, jumping to the todo marker line if
        present (falling back to the end of the file, or line 1 for
        a new/empty file).
        """
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)

        marker_line = find_marker_line(path, TODO_MARKER)
        if marker_line is not None:
            line = marker_line
        elif os.path.exists(path):
            with open(path) as f:
                line = sum(1 for _ in f) or 1
        else:
            line = 1

        try:
            subprocess.run([editor, f"+{line}", path])
        except FileNotFoundError:
            print(f"Error: Editor '{editor}' not found.", file=sys.stderr)
            sys.exit(1)


    def find_vault_markdown_files(notes_dir):
        """Recursively find every .md file under notes_dir, sorted.

        Hidden directories (e.g. ".obsidian", ".git", ".trash") are
        skipped.
        """
        files = []
        for root, dirs, filenames in os.walk(notes_dir):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for name in filenames:
                if name.endswith(".md"):
                    files.append(os.path.join(root, name))
        return sorted(files)


    def get_filtered_todos(path, args):
        todos = parse_journal_todos(path)
        journal_date = infer_journal_date(path)
        if journal_date is not None:
            apply_implicit_due_dates(todos, journal_date.strftime("%Y-%m-%d"))
        todos = filter_tree(todos, args.done)
        if args.today:
            today_str = datetime.date.today().strftime("%Y-%m-%d")
            todos = filter_due_today(todos, today_str)
        return todos


    def scope_message(args):
        if args.today:
            return "todos due today or overdue"
        if args.done:
            return "todos"
        return "open todos"


    def print_file_header(path):
        """Print path as a short, bold header: basename, no extension.

        E.g. ".../Daily/2026-10-09.md" is printed as just "2026-10-09".
        """
        label = os.path.splitext(os.path.basename(path))[0]
        print(c("1", label))


    def print_todo_tree(nodes, depth=0):
        for n in nodes:
            indent = INDENT_UNIT * depth
            suffix = format_task_metadata(n.get("meta", {}))
            if n.get("is_event"):
                box = c("36", "[i]")
                text = n["text"] + c("2", suffix)
            elif n.get("in_progress"):
                box = c("33", "[/]")
                text = n["text"] + c("2", suffix)
            elif n.get("cancelled"):
                box = c("31", "[-]")
                text = c("31;9", n["text"]) + c("2", suffix)
            elif n["done"]:
                box = c("32", "[x]")
                text = c("2;9", n["text"]) + c("2", suffix)
            else:
                box = "[ ]"
                text = n["text"] + c("2", suffix)
            print(f"{indent}- {box} {text}")
            for note in n["notes"]:
                note_indent = INDENT_UNIT * (depth + 1)
                print(f"{note_indent}- {c('2;3', note)}")
            print_todo_tree(n["children"], depth + 1)


    def main():
        parser = argparse.ArgumentParser(
            description=(
                "List todos (with sub-todos and notes) from a journal "
                "file."
            )
        )
        parser.add_argument(
            "-w", "--weekly", action="store_true",
            help="Read the weekly journal instead of the daily one."
        )
        parser.add_argument(
            "-o", "--offset", type=int, default=0,
            help="Offset in days (daily) or weeks (weekly) from today."
        )
        parser.add_argument(
            "-d", "--date", type=str,
            help=(
                "Date for the daily journal (weekday name, 'today', "
                "'tomorrow', 'yesterday', or a possibly-partial "
                "YYYY-MM-DD date). Ignored with --weekly."
            )
        )
        parser.add_argument(
            "-c", "--calendar", action="store_true",
            help=(
                "Interactively pick the date from a calendar (weeks "
                "start on Monday), instead of -d/--date. --offset "
                "still applies relative to the picked date."
            )
        )
        parser.add_argument(
            "-f", "--file", type=str,
            help=(
                "Read this file directly instead of resolving a journal "
                "file. Ignored with --all."
            )
        )
        parser.add_argument(
            "-r", "--range", nargs="+", metavar="DATE",
            help=(
                "Show todos across a range of daily journal files, from "
                "FROM through UNTIL (both inclusive, in either order). "
                "Dates use the same formats as -d/--date. If only one "
                "date is given, it's taken as UNTIL and FROM defaults "
                "to today. Not supported with --weekly, --all, --file, "
                "or --open."
            )
        )
        parser.add_argument(
            "-D", "--done", action="store_true",
            help="Also show completed todos (default: open todos only)."
        )
        parser.add_argument(
            "-a", "--all", action="store_true",
            help=(
                "Scan the whole vault - every .md file under NOTES_DIR - "
                "instead of a single journal file. Ignores "
                "-w/-o/-d/-f."
            )
        )
        parser.add_argument(
            "-t", "--today", action="store_true",
            help=(
                "Only show not-done todos due today or overdue "
                "(Obsidian Tasks \U0001F4C5 due date <= today). In a "
                "daily journal file, a todo with no explicit due date "
                "is implicitly due that day. Overrides --done."
            )
        )
        parser.add_argument(
            "-O", "--open", action="store_true",
            help=(
                "Open the journal file in an editor at the todo marker "
                "(%%%%insert_todo%%%%), i.e. where todos start, instead "
                "of listing them. Not supported with --all."
            )
        )
        parser.add_argument(
            "-e", "--editor", type=str, default=DEFAULT_EDITOR,
            help=f"Editor to use with --open (default: {DEFAULT_EDITOR})."
        )
        args = parser.parse_args()

        if args.open and args.all:
            print("Error: --open is not supported with --all.", file=sys.stderr)
            sys.exit(1)

        if args.range:
            for flag, value in (
                ("--weekly", args.weekly), ("--all", args.all),
                ("--file", args.file), ("--open", args.open),
            ):
                if value:
                    print(
                        f"Error: --range is not supported with {flag}.",
                        file=sys.stderr
                    )
                    sys.exit(1)

            if len(args.range) not in (1, 2):
                print(
                    "Error: --range takes one or two dates (FROM and "
                    "UNTIL, or just UNTIL).",
                    file=sys.stderr
                )
                sys.exit(1)

            daily_dir = os.getenv("JOURNAL_DAILY_PATH")
            if not daily_dir:
                print("Error: JOURNAL_DAILY_PATH not set.", file=sys.stderr)
                sys.exit(1)

            try:
                if len(args.range) == 1:
                    start_date = datetime.date.today()
                    end_date = parse_date(args.range[0])
                else:
                    start_date = parse_date(args.range[0])
                    end_date = parse_date(args.range[1])
            except ValueError:
                print(
                    f"Error: Invalid date in --range: "
                    f"{'/'.join(repr(d) for d in args.range)}.",
                    file=sys.stderr
                )
                sys.exit(1)

            if start_date > end_date:
                start_date, end_date = end_date, start_date

            any_found = False
            current = start_date
            while current <= end_date:
                path = os.path.join(
                    daily_dir, f"{current.strftime('%Y-%m-%d')}.md"
                )
                todos = get_filtered_todos(path, args)
                if todos:
                    if any_found:
                        print()
                    any_found = True
                    print_file_header(path)
                    print_todo_tree(todos)
                current += datetime.timedelta(days=1)

            if not any_found:
                print(
                    f"No {scope_message(args)} found between "
                    f"{start_date.strftime('%Y-%m-%d')} and "
                    f"{end_date.strftime('%Y-%m-%d')}"
                )
            return

        if args.all:
            notes_dir = os.getenv("NOTES_DIR")
            if not notes_dir:
                print("Error: NOTES_DIR not set.", file=sys.stderr)
                sys.exit(1)

            any_found = False
            for path in find_vault_markdown_files(notes_dir):
                todos = get_filtered_todos(path, args)
                if not todos:
                    continue
                if any_found:
                    print()
                any_found = True
                print(path)
                print_todo_tree(todos)

            if not any_found:
                print(f"No {scope_message(args)} found in vault ({notes_dir})")
            return

        if args.file:
            target_file = args.file
        elif args.weekly:
            weekly_dir = os.getenv("JOURNAL_WEEKLY_PATH")
            if not weekly_dir:
                print("Error: JOURNAL_WEEKLY_PATH not set.", file=sys.stderr)
                sys.exit(1)
            base_date = (
                pick_calendar_date() if args.calendar
                else datetime.date.today()
            )
            target_date = base_date + datetime.timedelta(weeks=args.offset)
            iso_year, iso_week, _ = target_date.isocalendar()
            target_file = os.path.join(
                weekly_dir, f"{iso_year}-W{iso_week:02d}.md"
            )
        else:
            daily_dir = os.getenv("JOURNAL_DAILY_PATH")
            if not daily_dir:
                print("Error: JOURNAL_DAILY_PATH not set.", file=sys.stderr)
                sys.exit(1)
            if args.calendar:
                base_date = pick_calendar_date()
            elif args.date:
                try:
                    base_date = parse_date(args.date)
                except ValueError:
                    print(
                        f"Error: Invalid date '{args.date}'.",
                        file=sys.stderr
                    )
                    sys.exit(1)
            else:
                base_date = datetime.date.today()
            target_date = base_date + datetime.timedelta(days=args.offset)
            target_file = os.path.join(
                daily_dir, f"{target_date.strftime('%Y-%m-%d')}.md"
            )

        if args.open:
            open_in_editor(target_file, args.editor)
            return

        if not os.path.exists(target_file):
            print(f"No journal file found at {target_file}", file=sys.stderr)
            sys.exit(1)

        todos = get_filtered_todos(target_file, args)

        if not todos:
            print(f"No {scope_message(args)} found in {target_file}")
            return

        print_file_header(target_file)
        print_todo_tree(todos)


    if __name__ == "__main__":
        main()
  ''
