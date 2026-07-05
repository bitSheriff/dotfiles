{ config, pkgs, ... }:

let
  notes = pkgs.writeShellApplication {
    name = "notes";
    runtimeInputs = [
      pkgs.fd
      pkgs.fzf
      pkgs.gnused
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      # Ensure NOTES_DIR is set
      if [[ -z "''${NOTES_DIR:-}" ]]; then
          echo "Error: NOTES_DIR is not set. Please set it to the directory where your notes are stored."
          exit 1
      fi

      editor="''${1:-nvim}" # Use the first argument if provided, otherwise default to nvim

      (
          cd "$NOTES_DIR" || exit 1 # Exit if NOTES_DIR cannot be changed to
          file="$(fd --extension md | fzf || true)"             # Capture the output of tv files
          # Trim and sanitize the file name
          if [[ -n "$file" ]]; then
              sanitized_file=$(echo "$file" | sed 's/[{}]//g' | xargs)
              if [[ -f "$sanitized_file" ]]; then
                  # Use the editor to open the selected file
                  "$editor" "$sanitized_file"
              else
                  echo "Error: No valid file selected or file does not exist."
              fi
          fi
      )
    '';
  };

  memo = pkgs.writeShellApplication {
    name = "memo";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gum
    ];
    text = ''
      # Preamble of the Memo
      MEMO_PRE="- **$(date +%H:%M):** "
      LINES_PRE="    - "

      if [[ -z "''${JOURNAL_DAILY_PATH:-}" ]]; then
          echo "Error: JOURNAL_DAILY_PATH not set"
          exit 1
      fi

      # Journal File where the memo gets added
      JOURNAL="$JOURNAL_DAILY_PATH/$(date +"%F").md"

      # check if file exists, if not create it
      if [[ ! -f "$JOURNAL" ]]; then
          touch "$JOURNAL"
      fi

      # check if file has new line at the end, if not add one
      if [[ -s "$JOURNAL" ]]; then
          test "$(tail -c 1 "$JOURNAL" | wc -l)" -eq 0 && echo "" >>"$JOURNAL"
      fi

      # decide if the input was given as a positional argument or parsed into (stdin)
      if [ $# -gt 0 ]; then
          # If there are arguments, join them into a single string and process
          input="$*"
          echo "$MEMO_PRE""$input" >>"$JOURNAL"
      else

          # Otherwise, use gum write to get the input
          input=$(gum write --header "Memo" --show-line-numbers --char-limit 0)

          # line counter
          count=0

          # Process the input line by line
          while IFS= read -r line; do
              # just print the preamble on the first line
              if [ $count -eq 0 ]; then
                  # Process the first line differently
                  echo "$MEMO_PRE""$line" >>"$JOURNAL"
              else
                  # Process the remaining lines
                  echo "$LINES_PRE""$line" >>"$JOURNAL"
              fi

              # Increment the counter
              count=$((count + 1))
          done <<<"$input"
      fi
    '';
  };

  memo-gui = pkgs.writeShellApplication {
    name = "memo-gui";
    runtimeInputs = [
      pkgs.kitty
      memo
    ];
    text = ''
      kitty --class floating --title "Pop-up Terminal" -e memo
    '';
  };

  inbox = pkgs.writeShellApplication {
    name = "inbox";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gum
      pkgs.wl-clipboard
    ];
    text = ''
      # Journal File where the memo gets added
      if [[ -z "''${INBOX:-}" ]]; then
          echo "Error: INBOX environment variable not set"
          exit 1
      fi
      INBOX_FILE="$INBOX"
      INBOX_DIR="$(dirname -- "$INBOX_FILE")"
      LINKS_FILE="$INBOX_DIR/Save 4 Later.md"
      TODO_FILE="$INBOX_DIR/Task Inbox.md"

      create_inbox_file() {
          # line conter
          count=0
          filename=""

          while IFS= read -r line; do
              # just print the preamble on the first line
              if [ $count -eq 0 ]; then
                  # the first line is the name of the file
                  filename="$INBOX_DIR/$line.md"

                  # write the name of the file as first Heading
                  echo "# $line" >>"$filename"
              else
                  # Process the remaining lines
                  echo "$line" >>"$filename"
              fi

              # Increment the counter
              count=$((count + 1))
          done
      }

      save_link() {
          # check if file exists, if not create it
          if [[ ! -f "$LINKS_FILE" ]]; then
              touch "$LINKS_FILE"
          fi
          # check if file has new line at the end, if not add one
          if [[ -s "$LINKS_FILE" ]]; then
              test "$(tail -c 1 "$LINKS_FILE" | wc -l)" -eq 0 && echo "" >>"$LINKS_FILE"
          fi

          local title
          title=$(gum input --placeholder "Title")
          local url
          url=$(gum input --placeholder "URL")
          local notes
          notes=$(gum input --placeholder "Notes")

          echo "- [ ] [$title]($url)" >>"$LINKS_FILE"

          # add notes if provided
          if [[ -n "$notes" ]]; then
              echo "    - $notes" >>"$LINKS_FILE"
          fi
      }

      save_todo(){
          # check if file exists, if not create it
          if [[ ! -f "$TODO_FILE" ]]; then
              touch "$TODO_FILE"
          fi
          # check if file has new line at the end, if not add one
          if [[ -s "$TODO_FILE" ]]; then
              test "$(tail -c 1 "$TODO_FILE" | wc -l)" -eq 0 && echo "" >>"$TODO_FILE"
          fi

          local title
          title=$(gum input --placeholder "Title")
          local notes
          notes=$(gum input --placeholder "Notes")

          echo "- [ ] $title" >>"$TODO_FILE"

          # add notes if provided
          if [[ -n "$notes" ]]; then
              echo "    - $notes" >>"$TODO_FILE"
          fi
      }

      OPTSTRING="cnlht"
      while getopts "''${OPTSTRING}" opt; do
          case "''${opt}" in
          h) # help/usage
              echo "inbox [opt] [text]"
              echo "Little script to save text in the inbox file. If no text is provided at stdin, it will provide promt(s) to fill in some text. Collecting text with stdin makes it possible to parse output of other programs to the inbox file."
              echo "Usage:"
              echo "  -h ... Print this help/usage message"
              echo "  -c ... Puts the clipboard contents to the inbox file"
              echo "  -n ... Create a new file in the inbox for this item"
              echo "  -t ... Create a new todo"
              echo "  -l ... Save a link, promts you to enter the name, url and some optional notes for this link"
              echo "         Links will get formated as a Todo"
              exit 0
              ;;
          c) # clipboard option
              printf "\n%s\n" "$(wl-paste)" >>"$INBOX_FILE"
              exit 0
              ;;
          n) # create new file
              create_inbox_file
              exit 0
              ;;
          l) # save link
              save_link
              exit 0
              ;;
          t) # save todo
              save_todo
              exit 0
              ;;
          *)
              exit 1
              ;;
          esac
      done

      # decide if the input was given as a positional argument or parsed into (stdin)
      if [ $# -gt 0 ]; then
          # If there are arguments, join them into a single string and process
          input="$*"
          printf "\n%s\n\n" "$input" >>"$INBOX_FILE"
      else
          # Otherwise, use gum write to get the input (stdin)
          input=$(gum write --header "Inbox" --show-line-numbers --char-limit 0)

          # line conter
          count=0

          while IFS= read -r line; do
              # just print the preamble on the first line
              if [ $count -eq 0 ]; then
                  # Process the first line differently
                  printf "\n%s\n" "$line" >>"$INBOX_FILE"
              else
                  # Process the remaining lines
                  echo "$line" >>"$INBOX_FILE"
              fi

              # Increment the counter
              count=$((count + 1))
          done <<<"$input"

          printf "\n\n" >>"$INBOX_FILE"
      fi
    '';
  };
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
            "task", nargs="*", help="The task content."
        )

        args = parser.parse_args()

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
                print("Enter todo (Ctrl+D to finish, Ctrl+C to cancel):")
                lines = []
                while True:
                    try:
                        prompt = "Todo: " if not lines else "      "
                        line = input(prompt)
                        lines.append(line)
                    except EOFError:
                        print()
                        break
                    except KeyboardInterrupt:
                        print("\nCancelled.")
                        sys.exit(0)
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

            if os.path.exists(journal_file) and \
               os.path.getsize(journal_file) > 0:
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
  imports = [
    ./jour.nix
  ];

  environment.sessionVariables = {
    NOTES_DIR = "$HOME/notes";
    INBOX = "$HOME/notes/Inbox/Inbox.md";
    INBOX_DIR = "$HOME/notes/Inbox";
    JOURNAL_DAILY_PATH = "$HOME/notes/Journal/Daily";
    JOURNAL_WEEKLY_PATH = "$HOME/notes/Journal/Weekly";
  };

  environment.systemPackages = with pkgs; [
    obsidian # the best note system
    gum # for cli inputs
    fd # find files
    fzf # to select files
    # own scripts
    notes
    memo
    memo-gui
    inbox
    todo
  ];

  programs.zsh.shellAliases = {
    daily = "jour";
    weekly = "jour --weekly";
  };

  systemd.user.services.note-backup = {
    description = "Backup notes daily with git";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "note-backup" ''
        # Ensure NOTES_DIR is set, fallback to ~/notes
        NOTES_DIR="''${NOTES_DIR:-$HOME/notes}"
        if [ ! -d "$NOTES_DIR" ]; then
          echo "Notes directory $NOTES_DIR does not exist."
          exit 0
        fi

        cd "$NOTES_DIR"

        if [ ! -d .git ]; then
          echo "Initializing git repository in $NOTES_DIR"
          ${pkgs.git}/bin/git init
        fi

        # Ensure git config has user and email (local settings to avoid failure)
        if ! ${pkgs.git}/bin/git config user.name >/dev/null 2>&1; then
          ${pkgs.git}/bin/git config --local user.name "Note Backup Service"
        fi
        if ! ${pkgs.git}/bin/git config user.email >/dev/null 2>&1; then
          ${pkgs.git}/bin/git config --local user.email "note-backup@localhost"
        fi

        ${pkgs.git}/bin/git add -A

        # Check if there are changes to commit, otherwise do nothing
        if ! ${pkgs.git}/bin/git diff --cached --quiet; then
          ${pkgs.git}/bin/git commit --no-gpg-sign -m "$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M')"
        fi
      ''}";
    };
  };

  systemd.user.timers.note-backup = {
    description = "Timer for daily note backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
