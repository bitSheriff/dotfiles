{ pkgs }:

pkgs.writers.writePython3Bin "todo" { } ''
    import os
    import re
    import sys
    import datetime
    import argparse
    import subprocess

    # Configuration for output formatting
    INDENT_UNIT = "    "


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


    def format_output_line(depth, is_desc, content):
        if is_desc:
            indent = INDENT_UNIT * (depth + 1)
            return f"{indent}- {content}"
        indent = INDENT_UNIT * depth
        return f"{indent}- [ ] {content}"


    # Target marker in the file (if found, insert after this line)
    TODO_MARKER = "%%insert_todo%%"


    def gum_input(placeholder):
        result = subprocess.run(
            ["gum", "input", "--placeholder", placeholder],
            capture_output=True, text=True
        )
        return result.stdout.strip()


    def gum_write(header):
        result = subprocess.run(
            ["gum", "write", "--header", header,
             "--show-line-numbers", "--char-limit", "0"],
            capture_output=True, text=True
        )
        return result.stdout


    def read_clipboard():
        result = subprocess.run(
            ["wl-paste"], capture_output=True, text=True
        )
        return result.stdout


    def ensure_trailing_newline(path):
        # Make sure the file exists and, if non-empty, ends with a newline
        # so new entries don't get glued onto the previous line.
        if not os.path.exists(path):
            os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
            open(path, "a").close()
            return
        if os.path.getsize(path) > 0:
            with open(path, "rb") as f:
                f.seek(-1, os.SEEK_END)
                last_byte = f.read(1)
            if last_byte != b"\n":
                with open(path, "a") as f:
                    f.write("\n")


    def get_inbox_dir():
        inbox_dir = os.getenv("INBOX_DIR")
        if inbox_dir:
            return inbox_dir
        inbox_file = os.getenv("INBOX")
        if inbox_file:
            return os.path.dirname(inbox_file)
        print("Error: INBOX_DIR (or INBOX) environment variable not set.",
              file=sys.stderr)
        sys.exit(1)


    def handle_link(args):
        """Save a link to the "Save 4 Later.md" file in the inbox dir.

        args.task may supply the url (and optionally the title) as
        positional arguments; anything missing is prompted for.
        """
        links_file = os.path.join(get_inbox_dir(), "Save 4 Later.md")
        ensure_trailing_newline(links_file)

        url = args.task[0] if len(args.task) >= 1 else gum_input("URL")
        title = args.task[1] if len(args.task) >= 2 else gum_input("Title")
        notes = gum_input("Notes")

        with open(links_file, "a") as f:
            f.write(f"- [ ] [{title}]({url})\n")
            if notes:
                f.write(f"    - {notes}\n")

        print(f"Saved link to {links_file}")


    def handle_inbox(args):
        """Append free-form text to the Inbox file.

        Text comes from (in order of precedence): the clipboard
        (-c), positional task arguments, or an interactive
        `gum write` prompt.
        """
        inbox_file = os.getenv("INBOX")
        if not inbox_file:
            print("Error: INBOX environment variable not set", file=sys.stderr)
            sys.exit(1)

        os.makedirs(
            os.path.dirname(os.path.abspath(inbox_file)), exist_ok=True
        )

        if args.clipboard:
            content = read_clipboard()
            text = f"\n{content}\n"
        elif args.task:
            input_text = " ".join(args.task)
            text = f"\n{input_text}\n\n"
        else:
            input_text = gum_write("Inbox")
            text = f"\n{input_text.rstrip(chr(10))}\n\n"

        with open(inbox_file, "a") as f:
            f.write(text)

        print(f"Added to {inbox_file}")


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
            print("Error: fzf or find not found in PATH.", file=sys.stderr)
            sys.exit(1)


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


    def main():
        parser = argparse.ArgumentParser(description="Add a todo task.")
        parser.add_argument(
            "-t", "--today", action="store_true", help="Set to today."
        )
        parser.add_argument(
            "-T", "--tomorrow", action="store_true", help="Set to tomorrow."
        )
        parser.add_argument(
            "-o", "--offset", type=int, default=0,
            help=(
                "Offset in days from today. Positive for future, "
                "negative for past."
            )
        )
        parser.add_argument(
            "-d", "--date", type=str,
            help=(
                "Set to a specific date. Accepts a weekday name "
                "(e.g. 'friday', 'fri', optionally prefixed with "
                "'next'), 'today', 'tomorrow', 'yesterday', or a "
                "YYYY-MM-DD date. The date may be partial - "
                "MM-DD (current year) or DD (current year and "
                "month) - and the missing parts are filled in."
            )
        )
        parser.add_argument(
            "-f", "--file", nargs="?", const="SELECT_WITH_FZF",
            help="Target markdown file."
        )
        parser.add_argument(
            "-i", "--inbox", action="store_true",
            help=(
                "Append text to the Inbox file instead of adding a todo. "
                "Combine with -c to use the clipboard, or provide task "
                "text/pipe stdin; otherwise falls back to `gum write`."
            )
        )
        parser.add_argument(
            "-c", "--clipboard", action="store_true",
            help="With -i, use clipboard contents instead of task text."
        )
        parser.add_argument(
            "-l", "--link", action="store_true",
            help=(
                "Save a link to \"Save 4 Later.md\" in the inbox dir. "
                "Optionally pass the url and title as positional "
                "arguments; anything missing (and notes) is prompted for."
            )
        )
        parser.add_argument(
            "task", nargs="*", help="The task content."
        )

        args = parser.parse_args()

        if args.link:
            handle_link(args)
            return

        if args.inbox:
            handle_inbox(args)
            return

        # Determine date (precedence: -d > -o > -T > -t)
        target_date = datetime.date.today()
        date_flag_used = False

        if args.date:
            try:
                target_date = parse_date(args.date)
                date_flag_used = True
            except ValueError:
                print(
                    f"Error: Invalid date '{args.date}'. Expected a "
                    "weekday, 'today'/'tomorrow'/'yesterday', or "
                    "YYYY-MM-DD (partial: MM-DD or DD).",
                    file=sys.stderr
                )
                sys.exit(1)
        elif args.offset:
            target_date += datetime.timedelta(days=args.offset)
            date_flag_used = True
        elif args.tomorrow:
            target_date += datetime.timedelta(days=1)
            date_flag_used = True
        elif args.today:
            date_flag_used = True

        # Format dates
        date_str = target_date.strftime("%Y-%m-%d")
        due_suffix = f" 📅 {date_str}" if date_flag_used else ""

        # Determine target file
        if args.file == "SELECT_WITH_FZF":
            journal_file = select_file_with_fzf()
        elif args.file:
            journal_file = args.file
        else:
            journal_path = os.getenv("JOURNAL_DAILY_PATH")
            if not journal_path:
                print("Error: JOURNAL_DAILY_PATH not set.", file=sys.stderr)
                sys.exit(1)
            journal_file = os.path.join(journal_path, f"{date_str}.md")

        # Ensure the target file's directory exists
        os.makedirs(
            os.path.dirname(os.path.abspath(journal_file)), exist_ok=True
        )

        # Get task input
        if args.task:
            # POSIX-style argument handling: each positional argument is
            # its own task/line (so `todo a b c` makes three todos, while
            # `todo "a b c"` - a single shell-quoted argument - makes one).
            lines = [
                sub_line
                for arg in args.task
                for sub_line in (arg.splitlines() or [arg])
            ]
        else:
            if sys.stdin.isatty():
                print(
                    "Enter todo (blank line, or Ctrl+D, to finish; "
                    "Ctrl+C to cancel):"
                )
                input_lines = []
                while True:
                    try:
                        prompt = "Todo: " if not input_lines else "      "
                        line = input(prompt)
                    except EOFError:
                        print()
                        break
                    except KeyboardInterrupt:
                        print("\nCancelled.")
                        sys.exit(0)
                    if not line.strip():
                        # A blank line finishes input, same as Ctrl+D - but
                        # only once something has actually been entered, so
                        # an accidental first Enter doesn't exit early.
                        if input_lines:
                            break
                        continue
                    input_lines.append(line)
                input_text = "\n".join(input_lines).strip()
            else:
                input_text = sys.stdin.read().strip()

            if not input_text:
                print("Error: No task content provided.", file=sys.stderr)
                sys.exit(1)

            lines = input_text.splitlines()

        if not any(line.strip() for line in lines):
            print("Error: No task content provided.", file=sys.stderr)
            sys.exit(1)

        # Prepare output lines
        output_lines = []

        for line in lines:
            stripped = line.strip()
            if not stripped:
                continue

            if not output_lines:
                # The very first line is always a new top-level todo,
                # regardless of any leading "-"/"." markers.
                depth, is_desc, content = 0, False, stripped
            else:
                depth, is_desc, content = parse_prefixed_line(stripped)

            out_line = format_output_line(depth, is_desc, content)
            if not is_desc and depth == 0 and due_suffix and "📅" not in out_line:
                out_line += due_suffix
            output_lines.append(out_line)

        # Write to file
        try:
            content_to_write = "\n".join(output_lines) + "\n"

            if (os.path.exists(journal_file) and
                    os.path.getsize(journal_file) > 0):
                with open(journal_file, "r") as f:
                    file_lines = f.readlines()

                marker_index = -1
                for i, line in enumerate(file_lines):
                    if TODO_MARKER in line:
                        marker_index = i
                        break

                if marker_index != -1:
                    file_lines.insert(marker_index + 1, content_to_write)
                    with open(journal_file, "w") as f:
                        f.writelines(file_lines)
                else:
                    needs_newline = not file_lines[-1].endswith("\n")
                    with open(journal_file, "a") as f:
                        if needs_newline:
                            f.write("\n")
                        f.write(content_to_write)
            else:
                with open(journal_file, "w") as f:
                    f.write(content_to_write)

            print(f"Added todo to {journal_file}")
        except Exception as e:
            print(f"Error writing to file: {e}", file=sys.stderr)
            sys.exit(1)


    if __name__ == "__main__":
        main()
  ''
