{ pkgs }:

pkgs.writers.writePython3Bin "todo-list" { } ''
    import os
    import re
    import sys
    import datetime
    import argparse

    # Configuration for output formatting (matches the `todo` script)
    INDENT_UNIT = "    "

    USE_COLOR = sys.stdout.isatty()


    def c(code, s):
        return f"\033[{code}m{s}\033[0m" if USE_COLOR else s


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
        ignored.

        Returns a list of top-level nodes, each
        {"text", "done", "notes": [...], "children": [...]}.
        """
        if not os.path.exists(path):
            return []

        with open(path) as f:
            lines = f.readlines()

        checklist_re = re.compile(
            r"^(?P<indent>\s*)-\s*\[(?P<mark>[ xX])\]\s*(?P<text>.*)$"
        )
        note_re = re.compile(r"^(?P<indent>\s*)-\s+(?P<text>.*)$")

        roots = []
        stack = {}  # depth -> node, for the todos currently "open" above us

        for raw in lines:
            line = raw.rstrip("\n")
            if not line.strip():
                continue

            m = checklist_re.match(line)
            if m:
                depth = len(m.group("indent")) // len(INDENT_UNIT)
                node = {
                    "text": m.group("text").strip(),
                    "done": m.group("mark").lower() == "x",
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

        return roots


    def filter_tree(nodes, show_done):
        if show_done:
            return nodes
        result = []
        for n in nodes:
            if n["done"]:
                continue
            n = dict(n)
            n["children"] = filter_tree(n["children"], show_done)
            result.append(n)
        return result


    def print_todo_tree(nodes, depth=0):
        for n in nodes:
            indent = INDENT_UNIT * depth
            if n["done"]:
                box = c("32", "[x]")
                text = c("2;9", n["text"])
            else:
                box = "[ ]"
                text = n["text"]
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
            "-f", "--file", type=str,
            help="Read this file directly instead of resolving a journal file."
        )
        parser.add_argument(
            "-a", "--all", action="store_true",
            help="Also show completed todos (default: open todos only)."
        )
        args = parser.parse_args()

        if args.file:
            target_file = args.file
        elif args.weekly:
            weekly_dir = os.getenv("JOURNAL_WEEKLY_PATH")
            if not weekly_dir:
                print("Error: JOURNAL_WEEKLY_PATH not set.", file=sys.stderr)
                sys.exit(1)
            target_date = (
                datetime.date.today() + datetime.timedelta(weeks=args.offset)
            )
            iso_year, iso_week, _ = target_date.isocalendar()
            target_file = os.path.join(
                weekly_dir, f"{iso_year}-W{iso_week:02d}.md"
            )
        else:
            daily_dir = os.getenv("JOURNAL_DAILY_PATH")
            if not daily_dir:
                print("Error: JOURNAL_DAILY_PATH not set.", file=sys.stderr)
                sys.exit(1)
            if args.date:
                try:
                    target_date = parse_date(args.date)
                except ValueError:
                    print(
                        f"Error: Invalid date '{args.date}'.",
                        file=sys.stderr
                    )
                    sys.exit(1)
            else:
                target_date = (
                    datetime.date.today()
                    + datetime.timedelta(days=args.offset)
                )
            target_file = os.path.join(
                daily_dir, f"{target_date.strftime('%Y-%m-%d')}.md"
            )

        if not os.path.exists(target_file):
            print(f"No journal file found at {target_file}", file=sys.stderr)
            sys.exit(1)

        todos = filter_tree(parse_journal_todos(target_file), args.all)

        if not todos:
            scope = "todos" if args.all else "open todos"
            print(f"No {scope} found in {target_file}")
            return

        print(target_file)
        print_todo_tree(todos)


    if __name__ == "__main__":
        main()
  ''
