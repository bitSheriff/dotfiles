{ pkgs, ... }:

let
  todo = pkgs.writers.writePython3Bin "todo" { } ''
    import os
    import sys
    import datetime
    import argparse
    import subprocess

    # Configuration for input parsing
    INPUT_DESC_PREFIX = "--"
    INPUT_SUB_PREFIX = "-"

    # Configuration for output formatting
    OUT_TODO = "- [ ] "
    OUT_NOTE = "    - "
    OUT_SUBTODO = "    - [ ] "

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

        # Fallback to standard format
        return datetime.datetime.strptime(date_str, "%Y-%m-%d").date()


    def main():
        parser = argparse.ArgumentParser(description="Add a todo task.")
        parser.add_argument(
            "-t", "--today", action="store_true", help="Set to today."
        )
        parser.add_argument(
            "-T", "--tomorrow", action="store_true", help="Set to tomorrow."
        )
        parser.add_argument(
            "-n", "--next", type=int, help="Set to N days from today."
        )
        parser.add_argument(
            "-d", "--date", type=str, help="Set to a specific date."
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

        # Determine date (precedence: -d > -n > -T > -t)
        target_date = datetime.date.today()
        date_flag_used = False

        if args.date:
            try:
                target_date = parse_date(args.date)
                date_flag_used = True
            except ValueError:
                print(f"Error: Invalid date '{args.date}'.", file=sys.stderr)
                sys.exit(1)
        elif args.next is not None:
            target_date += datetime.timedelta(days=args.next)
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
            input_text = " ".join(args.task)
        else:
            if sys.stdin.isatty():
                print(
                    "Enter todo (blank line, or Ctrl+D, to finish; "
                    "Ctrl+C to cancel):"
                )
                lines = []
                while True:
                    try:
                        prompt = "Todo: " if not lines else "      "
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
                        if lines:
                            break
                        continue
                    lines.append(line)
                input_text = "\n".join(lines).strip()
            else:
                input_text = sys.stdin.read().strip()

        if not input_text:
            print("Error: No task content provided.", file=sys.stderr)
            sys.exit(1)

        # Prepare output lines
        lines = input_text.splitlines()
        output_lines = []

        for line in lines:
            stripped = line.strip()
            if not stripped:
                continue

            is_desc = stripped.startswith(INPUT_DESC_PREFIX)
            is_sub = stripped.startswith(INPUT_SUB_PREFIX) and not is_desc

            if not output_lines:
                is_desc = is_sub = False

            if is_desc:
                content = stripped[len(INPUT_DESC_PREFIX):].strip()
                output_lines.append(f"{OUT_NOTE}{content}")
            elif is_sub:
                content = stripped[len(INPUT_SUB_PREFIX):].strip()
                output_lines.append(f"{OUT_SUBTODO}{content}")
            else:
                task_line = f"{OUT_TODO}{stripped}"
                if due_suffix and "📅" not in task_line:
                    task_line += due_suffix
                output_lines.append(task_line)

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
  '';
in
{
  environment.systemPackages = [
    todo
  ];
}
