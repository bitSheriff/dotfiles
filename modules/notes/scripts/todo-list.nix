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


    # Matches a checklist line ("- [ ] ...", "- [x] ...", ...). Shared by
    # parse_journal_todos (reading) and set_todo_mark (writing back a
    # single toggled state character from --tui).
    CHECKLIST_RE = re.compile(
        r"^(?P<indent>\s*)-\s*\[(?P<mark>[ xXiI/<>-])\]\s*(?P<text>.*)$"
    )


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
        and both are always kept regardless of --done/--overdue
        filtering (see filter_tree/filter_due_today). "- [-] ..."
        lines are cancelled todos and "- [<] ..." lines are
        delegated todos - both count as "done" (hidden unless
        --done is passed) but are rendered distinctly. "- [>] ..."
        lines are forwarded todos - they count as not done, same as
        "- [ ] ...", but are rendered distinctly.

        Returns a list of top-level nodes, each
        {"text", "done", "is_event", "in_progress", "cancelled",
        "delegated", "forwarded", "meta": {...}, "notes": [...],
        "children": [...]}.
        """
        if not os.path.exists(path):
            return []

        with open(path) as f:
            lines = f.readlines()

        note_re = re.compile(r"^(?P<indent>\s*)-\s+(?P<text>.*)$")

        roots = []
        stack = {}  # depth -> node, for the todos currently "open" above us

        for lineno, raw in enumerate(lines, start=1):
            line = raw.rstrip("\n")
            if not line.strip():
                # A blank line ends the current contiguous todo block - a
                # note/sub-todo only belongs to a todo if it's on a line
                # directly below it (same scope, no gaps), so any open
                # parents are no longer eligible to receive children/notes.
                stack = {}
                continue

            m = CHECKLIST_RE.match(line)
            if m:
                depth = len(m.group("indent")) // len(INDENT_UNIT)
                text, meta = extract_task_metadata(m.group("text").strip())
                mark = m.group("mark").lower()
                node = {
                    "text": text,
                    "state": mark,
                    "line": lineno,
                    "done": mark in ("x", "-", "<"),
                    "is_event": mark == "i",
                    "in_progress": mark == "/",
                    "cancelled": mark == "-",
                    "delegated": mark == "<",
                    "forwarded": mark == ">",
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


    # Checklist state characters (the content of "[ ]") and their names,
    # used by --state and in its help/error text.
    VALID_STATES = {
        " ": "open",
        "x": "done",
        "i": "event",
        "/": "in-progress",
        "-": "cancelled",
        "<": "delegated",
        ">": "forwarded",
    }


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


    # States treated as "not done" for overdue/due-today purposes. A
    # calendar event ("i") is deliberately excluded - it's a point-in-
    # time appointment, not an actionable todo, so it should never be
    # flagged as overdue just for sitting in an old daily journal.
    NOT_DONE_DUE_STATES = (" ", ">")


    def filter_due_today(nodes, today_str):
        """Keep not-done todos due today or overdue, plus their ancestors.

        A todo matches if its state is open (" ") or forwarded (">")
        and its due date is today or earlier (ISO YYYY-MM-DD strings
        sort chronologically, so a plain string comparison is enough -
        overdue todos are meant to get done today too). In-progress
        todos ("- [/] ...") always match, regardless of their due
        date, since they're still actively being worked on. Calendar
        events ("- [i] ...") never match here - they aren't "not
        done"/overdue, they're just appointments. Ancestors of a
        matching todo are kept (without being considered matches
        themselves) purely to preserve context; todos/branches with no
        matching descendant are dropped.
        """
        result = []
        for n in nodes:
            due = n.get("meta", {}).get("due")
            matches = n.get("in_progress") or (
                n.get("state") in NOT_DONE_DUE_STATES
                and due is not None and due <= today_str
            )
            kept_children = filter_due_today(n["children"], today_str)
            if matches or kept_children:
                n = dict(n)
                n["children"] = kept_children
                result.append(n)
        return result


    def filter_by_state(nodes, state):
        """Keep only todos with the given checklist state, plus ancestors.

        A todo matches if its own state character equals state.
        Ancestors of a matching todo are kept (without being
        considered matches themselves) purely to preserve context;
        todos/branches with no matching descendant are dropped.
        """
        result = []
        for n in nodes:
            matches = n.get("state") == state
            kept_children = filter_by_state(n["children"], state)
            if matches or kept_children:
                n = dict(n)
                n["children"] = kept_children
                result.append(n)
        return result


    def set_todo_mark(path, line_no, new_mark):
        """Overwrite the checklist mark on one line of a journal file.

        Rewrites only the single character inside "[ ]" on the given
        1-indexed line - everything else on that line (text, emoji
        metadata, indentation) and every other line in the file is
        left untouched. Used by --tui to toggle a todo's state in
        place. Returns True on success, False if the line doesn't
        exist or isn't a checklist line anymore (e.g. file changed
        concurrently).
        """
        with open(path) as f:
            lines = f.readlines()

        idx = line_no - 1
        if not (0 <= idx < len(lines)):
            return False

        raw = lines[idx]
        line = raw.rstrip("\n")
        eol = raw[len(line):]
        m = CHECKLIST_RE.match(line)
        if not m:
            return False

        start, end = m.span("mark")
        lines[idx] = line[:start] + new_mark + line[end:] + eol

        with open(path, "w") as f:
            f.writelines(lines)
        return True


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


    def find_daily_journal_files(daily_dir):
        """Return every daily journal file ("YYYY-MM-DD.md") directly
        under daily_dir, sorted chronologically.
        """
        if not os.path.isdir(daily_dir):
            return []
        return sorted(
            os.path.join(daily_dir, name)
            for name in os.listdir(daily_dir)
            if DAILY_FILENAME_RE.match(name)
        )


    def get_filtered_todos(path, args):
        todos = parse_journal_todos(path)
        journal_date = infer_journal_date(path)
        if journal_date is not None:
            apply_implicit_due_dates(todos, journal_date.strftime("%Y-%m-%d"))
        if args.state is not None:
            return filter_by_state(todos, args.state)
        todos = filter_tree(todos, args.done)
        if args.overdue:
            today_str = datetime.date.today().strftime("%Y-%m-%d")
            todos = filter_due_today(todos, today_str)
        return todos


    def scope_message(args):
        if args.state is not None:
            return f"{VALID_STATES[args.state]} todos"
        if args.overdue:
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
            elif n.get("delegated"):
                box = c("35", "[<]")
                text = c("35;9", n["text"]) + c("2", suffix)
            elif n.get("forwarded"):
                box = c("34", "[>]")
                text = n["text"] + c("2", suffix)
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


    def output_sections(
        sections, empty_message, args, header_fn=None, refresh_paths=None,
    ):
        """Print sections, or hand them to the interactive --tui browser.

        sections is a list of (path, todos) pairs (todos possibly
        empty - those are skipped). header_fn defaults to
        print_file_header (short, bold basename); pass print instead
        for a full-path header (e.g. --all). refresh_paths, if given,
        is a callable returning a fresh path list - used by --tui's
        "r" key to pick up brand new journal files that didn't exist
        (or had no matching todos) when the browser was launched.
        """
        header_fn = header_fn or print_file_header
        non_empty = [(path, todos) for path, todos in sections if todos]

        if args.tui:
            if not non_empty:
                print(empty_message)
                return
            run_tui([path for path, _ in non_empty], args, refresh_paths)
            return

        if not non_empty:
            print(empty_message)
            return

        for i, (path, todos) in enumerate(non_empty):
            if i:
                print()
            header_fn(path)
            print_todo_tree(todos)


    # Curses colors for --tui, matching the ANSI codes used by c()/
    # print_todo_tree as closely as curses allows.
    TUI_STATE_COLOR_PAIR = {
        "x": 1,   # done - green
        "i": 2,   # event - cyan
        "/": 3,   # in-progress - yellow
        "-": 4,   # cancelled - red
        "<": 5,   # delegated - magenta
        ">": 6,   # forwarded - blue
    }


    def run_tui(paths, args, refresh_paths=None):
        """Launch an interactive browser over the given journal files.

        Lets you move through the todo tree(s) (one section per path),
        expand/collapse branches, jump between day sections, and
        toggle a todo's checklist state in place - this rewrites only
        the single mark character on that todo's exact source line,
        nothing else is touched. Pressing "r" reloads every file from
        disk (picking up todos added elsewhere, e.g. via `todo`, while
        the browser is open) and, if refresh_paths is given, also
        re-discovers brand new journal files that weren't part of the
        original path list.
        """
        collapsed = {}  # (path, line) -> True if collapsed

        def build_rows():
            rows = []
            for path in paths:
                todos = get_filtered_todos(path, args)
                if not todos:
                    continue
                rows.append({"type": "header", "path": path})
                _add_rows(rows, path, todos, 0)
            return rows

        def _add_rows(rows, path, nodes, depth):
            for n in nodes:
                key = (path, n["line"])
                rows.append({
                    "type": "todo", "path": path, "node": n,
                    "depth": depth, "key": key,
                })
                if not collapsed.get(key):
                    for note in n["notes"]:
                        rows.append({
                            "type": "note", "text": note, "depth": depth + 1,
                        })
                    _add_rows(rows, path, n["children"], depth + 1)

        def first_selectable(rows):
            for i, r in enumerate(rows):
                if r["type"] == "todo":
                    return i
            return 0

        def last_selectable(rows):
            for i in range(len(rows) - 1, -1, -1):
                if rows[i]["type"] == "todo":
                    return i
            return 0

        def move(rows, pos, delta):
            i = pos
            while True:
                i += delta
                if i < 0 or i >= len(rows):
                    return pos
                if rows[i]["type"] == "todo":
                    return i

        def jump_section(rows, pos, delta):
            headers = [i for i, r in enumerate(rows) if r["type"] == "header"]
            if not headers:
                return pos
            if delta > 0:
                later = [i for i in headers if i > pos]
                target = later[0] if later else headers[-1]
            else:
                earlier = [i for i in headers if i < pos]
                target = earlier[-1] if earlier else headers[0]
            i = target
            while i < len(rows) and rows[i]["type"] != "todo":
                i += 1
            return i if i < len(rows) else pos

        def parent_row(rows, pos):
            depth = rows[pos].get("depth", 0)
            for i in range(pos - 1, -1, -1):
                r = rows[i]
                if r["type"] == "todo" and r["depth"] < depth:
                    return i
            return pos

        def find_key(rows, key, fallback):
            for i, r in enumerate(rows):
                if r.get("key") == key:
                    return i
            return min(fallback, len(rows) - 1) if rows else 0

        def nearest_selectable(rows, pos):
            if not rows:
                return 0
            pos = max(0, min(pos, len(rows) - 1))
            if rows[pos]["type"] == "todo":
                return pos
            for i in range(pos, len(rows)):
                if rows[i]["type"] == "todo":
                    return i
            for i in range(pos, -1, -1):
                if rows[i]["type"] == "todo":
                    return i
            return 0

        def render(stdscr, rows, sel, top):
            stdscr.erase()
            max_y, max_x = stdscr.getmaxyx()
            body_h = max(1, max_y - 2)
            if sel < top:
                top = sel
            elif sel >= top + body_h:
                top = sel - body_h + 1

            for i in range(body_h):
                ridx = top + i
                if ridx >= len(rows):
                    break
                row = rows[ridx]
                reverse = curses.A_REVERSE if ridx == sel else 0
                if row["type"] == "header":
                    label = os.path.splitext(os.path.basename(row["path"]))[0]
                    attr = curses.A_BOLD | reverse
                    stdscr.addstr(i, 0, label[:max_x - 1], attr)
                elif row["type"] == "note":
                    indent = INDENT_UNIT * row["depth"]
                    text = f"{indent}- {row['text']}"
                    stdscr.addstr(i, 0, text[:max_x - 1], curses.A_DIM | reverse)
                else:
                    n = row["node"]
                    indent = INDENT_UNIT * row["depth"]
                    box = f"[{n['state']}]"
                    suffix = format_task_metadata(n.get("meta", {}))
                    marker = ""
                    if n["children"] and collapsed.get(row["key"]):
                        marker = " (...)"
                    text = f"{indent}- {box} {n['text']}{suffix}{marker}"
                    pair = TUI_STATE_COLOR_PAIR.get(n["state"])
                    attr = curses.color_pair(pair) if pair else 0
                    if n["done"]:
                        attr |= curses.A_DIM
                    stdscr.addstr(i, 0, text[:max_x - 1], attr | reverse)

            footer = (
                "j/k move  h/l collapse/expand  n/p next/prev day  "
                "g/G top/bottom  space/x/i//-/</> set state  "
                "D toggle done  r reload  q quit"
            )
            stdscr.addstr(max_y - 1, 0, footer[:max_x - 1], curses.A_REVERSE)
            stdscr.refresh()
            return top

        def _inner(stdscr):
            curses.curs_set(0)
            stdscr.keypad(True)
            curses.start_color()
            curses.use_default_colors()
            curses.init_pair(1, curses.COLOR_GREEN, -1)
            curses.init_pair(2, curses.COLOR_CYAN, -1)
            curses.init_pair(3, curses.COLOR_YELLOW, -1)
            curses.init_pair(4, curses.COLOR_RED, -1)
            curses.init_pair(5, curses.COLOR_MAGENTA, -1)
            curses.init_pair(6, curses.COLOR_BLUE, -1)

            rows = build_rows()
            if not rows:
                return
            sel = first_selectable(rows)
            top = 0

            while True:
                top = render(stdscr, rows, sel, top)
                key = stdscr.getch()

                if key in (ord("q"), 27):
                    return
                elif key in (ord("j"), curses.KEY_DOWN):
                    sel = move(rows, sel, 1)
                elif key in (ord("k"), curses.KEY_UP):
                    sel = move(rows, sel, -1)
                elif key == ord("g"):
                    sel = first_selectable(rows)
                elif key == ord("G"):
                    sel = last_selectable(rows)
                elif key == ord("n"):
                    sel = jump_section(rows, sel, 1)
                elif key == ord("p"):
                    sel = jump_section(rows, sel, -1)
                elif key in (ord("h"), curses.KEY_LEFT):
                    row = rows[sel]
                    rkey = row["key"]
                    if row["node"]["children"] and not collapsed.get(rkey):
                        collapsed[rkey] = True
                        rows = build_rows()
                        sel = find_key(rows, rkey, sel)
                    else:
                        sel = parent_row(rows, sel)
                elif key in (ord("l"), curses.KEY_RIGHT):
                    row = rows[sel]
                    rkey = row["key"]
                    if row["node"]["children"] and collapsed.get(rkey):
                        collapsed[rkey] = False
                        rows = build_rows()
                        sel = find_key(rows, rkey, sel)
                elif key in (
                    ord(" "), ord("x"), ord("i"), ord("/"),
                    ord("-"), ord("<"), ord(">"),
                ):
                    row = rows[sel]
                    mark = " " if key == ord(" ") else chr(key)
                    set_todo_mark(row["path"], row["node"]["line"], mark)
                    rows = build_rows()
                    if not rows:
                        return
                    sel = nearest_selectable(rows, sel)
                elif key == ord("D"):
                    args.done = not args.done
                    rows = build_rows()
                    if not rows:
                        return
                    sel = nearest_selectable(rows, sel)
                elif key == ord("r"):
                    rkey = rows[sel].get("key") if rows else None
                    if refresh_paths is not None:
                        paths[:] = refresh_paths()
                    rows = build_rows()
                    if not rows:
                        return
                    sel = find_key(rows, rkey, sel) if rkey else sel

                if not rows:
                    return
                sel = max(0, min(sel, len(rows) - 1))

        curses.wrapper(_inner)


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
            "--overdue", action="store_true",
            help=(
                "Only show not-done todos due today or overdue "
                "(Obsidian Tasks \U0001F4C5 due date <= today). In a "
                "daily journal file, a todo with no explicit due date "
                "is implicitly due that day - so a not-done todo left "
                "behind in an old daily journal counts as overdue. "
                "Overrides --done. On its own (no -d/-o/-c/-w/-f/-a/-r), "
                "scans every daily journal file for overdue/due-today "
                "todos instead of just today's."
            )
        )
        parser.add_argument(
            "-s", "--state", type=str, default=None,
            help=(
                "Only show todos with this checklist state - the "
                "character inside \"[ ]\": " + ", ".join(
                    f"{s!r} ({name})" for s, name in VALID_STATES.items()
                ) + ". Overrides --done/--overdue."
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
        parser.add_argument(
            "--tui", action="store_true",
            help=(
                "Browse the selected todos interactively instead of "
                "printing them: j/k move, h/l collapse/expand, n/p jump "
                "to the next/previous day, g/G top/bottom, space/x/i//"
                "/-/</> set a todo's state in place (rewrites just that "
                "line), D toggles showing done todos, r reloads every "
                "file from disk (picking up todos added elsewhere, and "
                "newly created journal files), q quits. With no other "
                "file-selection flag, defaults to the same overdue/"
                "due-today scan as a bare --overdue. Not supported with "
                "--open."
            )
        )
        args = parser.parse_args()

        if args.tui and args.open:
            print("Error: --tui is not supported with --open.", file=sys.stderr)
            sys.exit(1)

        if args.tui and not args.overdue and not (
            args.file or args.weekly or args.all or args.date
            or args.offset or args.calendar or args.range or args.state
        ):
            # Bare --tui, just like bare --overdue, means "show me what
            # needs attention" - scan every daily journal for
            # overdue/due-today todos instead of just today's file.
            args.overdue = True

        if args.state is not None:
            state = args.state.lower()
            if len(state) != 1 or state not in VALID_STATES:
                valid = ", ".join(f"{s!r}" for s in VALID_STATES)
                print(
                    f"Error: Invalid --state {args.state!r}. Expected "
                    f"one of: {valid}.",
                    file=sys.stderr
                )
                sys.exit(1)
            args.state = state

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

            sections = []
            current = start_date
            while current <= end_date:
                path = os.path.join(
                    daily_dir, f"{current.strftime('%Y-%m-%d')}.md"
                )
                sections.append((path, get_filtered_todos(path, args)))
                current += datetime.timedelta(days=1)

            output_sections(
                sections,
                f"No {scope_message(args)} found between "
                f"{start_date.strftime('%Y-%m-%d')} and "
                f"{end_date.strftime('%Y-%m-%d')}",
                args,
            )
            return

        # A bare --overdue (no other file-selection flag) means "what's
        # overdue or due today" - that can only be answered by scanning
        # every daily journal file, not just today's, since a not-done
        # todo left behind in an old journal is implicitly overdue.
        if args.overdue and not (
            args.file or args.weekly or args.all
            or args.date or args.offset or args.calendar
        ):
            daily_dir = os.getenv("JOURNAL_DAILY_PATH")
            if not daily_dir:
                print("Error: JOURNAL_DAILY_PATH not set.", file=sys.stderr)
                sys.exit(1)

            sections = [
                (path, get_filtered_todos(path, args))
                for path in find_daily_journal_files(daily_dir)
            ]
            output_sections(
                sections, f"No {scope_message(args)} found in {daily_dir}",
                args,
                refresh_paths=lambda: find_daily_journal_files(daily_dir),
            )
            return

        if args.all:
            notes_dir = os.getenv("NOTES_DIR")
            if not notes_dir:
                print("Error: NOTES_DIR not set.", file=sys.stderr)
                sys.exit(1)

            sections = [
                (path, get_filtered_todos(path, args))
                for path in find_vault_markdown_files(notes_dir)
            ]
            output_sections(
                sections,
                f"No {scope_message(args)} found in vault ({notes_dir})",
                args, header_fn=print,
                refresh_paths=lambda: find_vault_markdown_files(notes_dir),
            )
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
        output_sections(
            [(target_file, todos)],
            f"No {scope_message(args)} found in {target_file}",
            args,
        )


    if __name__ == "__main__":
        main()
  ''
