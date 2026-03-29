
{ config, pkgs, ... }:

let
  daily = pkgs.writers.writePython3Bin "daily" { } ''
    import os
    import sys
    from datetime import datetime, timedelta
    import subprocess

    # Define the default editor
    DEFAULT_EDITOR = "nvim"


    def open_daily_journal(offset=0, editor=None):
        """
        Opens the daily journal file with the given editor.

        Parameters:
        - offset (int): The day offset. Positive for future, negative for past.
        - editor (str): The editor to use.
        """
        # Determine the editor to use
        editor_to_use = editor or DEFAULT_EDITOR

        # Define the NOTES_DIR environment variable
        daily_dir = os.getenv("JOURNAL_DAILY_PATH")
        if not daily_dir:
            msg = "JOURNAL_DAILY_PATH environment variable is not set."
            raise EnvironmentError(msg)

        # Calculate the target date with the offset
        target_date = datetime.now() + timedelta(days=offset)
        formatted_date = target_date.strftime("%Y-%m-%d")

        # Construct the path to the journal file
        journal_file = os.path.join(daily_dir, f"{formatted_date}.md")

        # Open the file with the chosen editor
        subprocess.run([editor_to_use, journal_file])


    # Main logic
    if __name__ == "__main__":
        if len(sys.argv) == 1:
            # No arguments: Open today's journal with the default editor
            open_daily_journal()
        elif len(sys.argv) == 2:
            # Only editor is specified
            editor_arg = sys.argv[1]
            open_daily_journal(editor=editor_arg)
        elif len(sys.argv) == 3:
            # Offset and editor are specified
            try:
                offset_arg = int(sys.argv[1])
            except ValueError:
                print("Offset must be an integer.")
                sys.exit(1)
            editor_arg = sys.argv[2]
            open_daily_journal(offset=offset_arg, editor=editor_arg)
        else:
            # Incorrect usage
            print("Usage: open_journal [offset] editor")
            print("  If offset is provided, editor must also be specified.")
            print("  Examples:")
            print("    open_journal         # Opens today's journal")
            print("    open_journal nvim    # Opens today's journal with nvim")
            print("    open_journal -1 nvim # Opens yesterday's journal")
            print("    open_journal +1 nvim # Opens tomorrow's journal")
            sys.exit(1)
  '';
notes = pkgs.writeShellScriptBin "notes" ''
  # Ensure NOTES_DIR is set
  if [[ -z "$NOTES_DIR" ]]; then
      echo "Error: NOTES_DIR is not set. Please set it to the directory where your notes are stored."
      exit 1
  fi

  editor="''${1:-nvim}" # Use the first argument if provided, otherwise default to nvim

  (
      cd "$NOTES_DIR" || exit 1 # Exit if NOTES_DIR cannot be changed to
      file="$(fzf)"             # Capture the output of tv files
      # Trim and sanitize the file name
      sanitized_file=$(echo "$file" | sed 's/[{}]//g' | xargs)
      if [[ -n "$sanitized_file" && -f "$sanitized_file" ]]; then
          # Use the editor to open the selected file
          "$editor" "$sanitized_file"
      else
          echo "Error: No valid file selected or file does not exist."
      fi
  )
'';

memo = pkgs.writeShellScriptBin "memo" ''
  source "$HOME/.config/shell/envvars"
  source "$HOME/.config/shell/secrets"
  source "$LIB_PATH/my_lib.sh"

  # Preamble of the Memo
  MEMO_PRE="- **$(date +%H:%M):** "
  LINES_PRE="    - "

  # Journal File where the memo gets added
  JOURNAL=$JOURNAL_DAILY_PATH/$(date +"%F").md

  # check if file has new line at the end, if not add one
  test "$(tail -c 1 "$JOURNAL" | wc -l)" -eq 0 && echo "" >>"$JOURNAL"

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

memo-gui = pkgs.writeShellScriptBin "memo-gui" ''
  kitty --class floating --title "Pop-up Terminal" -e memo
'';

inbox = pkgs.writeShellScriptBin "inbox" ''
  # Preamble of the Memo
  INBOX_PRE=""
  INBOX_POST=""

  # Journal File where the memo gets added
  INBOX_FILE="$INBOX"
  INBOX_DIR="$(dirname -- "$INBOX_FILE")"
  LINKS_FILE="$INBOX_DIR/Save 4 Later.md"

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
      local title=$(gum input --placeholder "Title")
      local url=$(gum input --placeholder "URL")
      local notes=$(gum input --placeholder "Notes")

      echo "- [ ] [$title]($url)" >>"$LINKS_FILE"

      # add notes if provided
      if [[ -n "$notes" ]]; then
          echo "    - $notes" >>"$LINKS_FILE"
      fi

      echo -e "\n" >>"$LINKS_FILE"
  }

  OPTSTRING="cnlh"
  while getopts "''${OPTSTRING}" opt; do
      case "''${opt}" in
      h) # help/usage
          echo "inbox [opt] [text]"
          echo "Little script to save text in the inbox file. If no text is provided at stdin, it will provide promt(s) to fill in some text. Collecting text with stdin makes it possible to parse output of other programs to the inbox file."
          echo "Usage:"
          echo "  -h ... Print this help/usage message"
          echo "  -c ... Puts the clipboard contents to the inbox file"
          echo "  -n ... Create a new file in the inbox for this item"
          echo "  -l ... Save a link, promts you to enter the name, url and some optional notes for this link"
          echo "         Links will get formated as a Todo"
          exit 0
          ;;
      c) # clipboard option
          echo -e "\n$(wl-paste)" >>"$INBOX_FILE"
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
      esac
  done

  # decide if the input was given as a positional argument or parsed into (stdin)
  if [ $# -gt 0 ]; then
      # If there are arguments, join them into a single string and process
      input="$*"
      echo -e "\n$input\n" >>"$INBOX_FILE"
  else
      # Otherwise, use gum write to get the input (stdin)
      input=$(gum write --header "Inbox" --show-line-numbers --char-limit 0)

      # line conter
      count=0

      while IFS= read -r line; do
          # just print the preamble on the first line
          if [ $count -eq 0 ]; then
              # Process the first line differently
              echo -e "\n$line" >>"$INBOX_FILE"
          else
              # Process the remaining lines
              echo "$line" >>"$INBOX_FILE"
          fi

          # Increment the counter
          count=$((count + 1))
      done <<<"$input"

      echo -e "\n" >>"$INBOX_FILE"
  fi
'';
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
  environment.systemPackages = with pkgs; [
    obsidian # the best note system
    daily
    notes
    memo
    memo-gui
    inbox
    todo
  ];
}

