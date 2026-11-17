{ pkgs, todoCommon }:

pkgs.writers.writePython3Bin "todo" { libraries = [ todoCommon ]; } ''
  import os
  import sys
  import datetime
  import argparse
  import subprocess
  import readline  # noqa: F401  (enables arrow-key/line editing for input())
  from todo_common import (
      TODO_MARKER, VALID_STATES,
      parse_prefixed_line, format_output_line, parse_date,
      resolve_due_date_file, apply_inline_options,
      select_file_with_fzf, pick_calendar_date,
  )


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
      (-C), positional task arguments, or an interactive
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


  def main():
      parser = argparse.ArgumentParser(description="Add a todo task.")
      parser.add_argument(
          "-w", "--weekly", action="store_true",
          help=(
              "Add to the weekly journal (JOURNAL_WEEKLY_PATH) instead "
              "of the daily one. -o/--offset is interpreted in weeks "
              "rather than days. Ignored with -f/--file."
          )
      )
      parser.add_argument(
          "-t", "--today", action="store_true", help="Set to today."
      )
      parser.add_argument(
          "-T", "--tomorrow", action="store_true", help="Set to tomorrow."
      )
      parser.add_argument(
          "-o", "--offset", type=int, default=0,
          help=(
              "Offset in days from today (or weeks, with -w/--weekly). "
              "Positive for future, negative for past."
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
              "Combine with -C to use the clipboard, or provide task "
              "text/pipe stdin; otherwise falls back to `gum write`."
          )
      )
      parser.add_argument(
          "-C", "--clipboard", action="store_true",
          help="With -i, use clipboard contents instead of task text."
      )
      parser.add_argument(
          "-c", "--calendar", action="store_true",
          help=(
              "Interactively pick the date from a calendar (weeks "
              "start on Monday). Overrides -d/--date, -o/--offset, "
              "-T/--tomorrow and -t/--today."
          )
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
          "-s", "--state", type=str, default=None,
          help=(
              "Checklist state for the new todo(s) - the character "
              "to put inside \"[ ]\", same meaning as todo-list's "
              "--state: " + ", ".join(
                  f"{s!r} ({name})" for s, name in VALID_STATES.items()
              ) + ". Default: ' ' (open). Only applies to new "
              "top-level todos, not sub-todos/notes."
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

      # Determine date (precedence: -d > -o > -T > -t)
      target_date = datetime.date.today()
      date_flag_used = False

      if args.calendar:
          target_date = pick_calendar_date()
          date_flag_used = True
      elif args.date:
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
          if args.weekly:
              target_date += datetime.timedelta(weeks=args.offset)
          else:
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
      elif args.weekly:
          weekly_path = os.getenv("JOURNAL_WEEKLY_PATH")
          if not weekly_path:
              print(
                  "Error: JOURNAL_WEEKLY_PATH not set.", file=sys.stderr
              )
              sys.exit(1)
          iso_year, iso_week, _ = target_date.isocalendar()
          journal_file = os.path.join(
              weekly_path, f"{iso_year}-W{iso_week:02d}.md"
          )
      else:
          journal_path = os.getenv("JOURNAL_DAILY_PATH")
          if not journal_path:
              print("Error: JOURNAL_DAILY_PATH not set.", file=sys.stderr)
              sys.exit(1)

          assigned_file = os.path.join(journal_path, f"{date_str}.md")
          today_str = datetime.date.today().strftime("%Y-%m-%d")

          if date_str == today_str or os.path.exists(assigned_file):
              # The due date has its own journal file (or is today) -
              # land the todo there. due_suffix (set above from
              # date_flag_used) stays as-is, so it's tagged with its
              # due date either way - same as the fallback below.
              journal_file = assigned_file
          else:
              # Daily notes are usually pre-created a month or two in
              # advance, but the assigned date's note doesn't exist
              # yet (e.g. it's further out, or pre-creation hasn't
              # run). Rather than silently creating a new,
              # out-of-sequence daily note, fall back to today's file
              # instead; due_suffix (already set above) makes sure
              # the intended date isn't lost.
              journal_file = os.path.join(journal_path, f"{today_str}.md")

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

      # Prepare output blocks, one per top-level todo. A top-level
      # line (and any sub-todos/notes following it) normally lands
      # in journal_file, but a leading "<...>" inline-options block
      # on that line (see apply_inline_options) can redirect just
      # that block to a different daily file - this is what lets a
      # single interactive multi-line entry mix e.g. a today todo
      # with a tomorrow one.
      blocks = []
      current_file = journal_file
      current_lines = []

      for line in lines:
          stripped = line.strip()
          if not stripped:
              continue

          if not blocks and not current_lines:
              # The very first line is always a new top-level todo,
              # regardless of any leading "-"/"." markers.
              depth, is_desc, content = 0, False, stripped
          else:
              depth, is_desc, content = parse_prefixed_line(stripped)

          is_new_top_level = not is_desc and depth == 0

          try:
              content, inline_mark, due = apply_inline_options(
                  content, is_desc
              )
          except ValueError as e:
              print(f"Error: {e}", file=sys.stderr)
              sys.exit(1)

          if is_new_top_level:
              if current_lines:
                  blocks.append((current_file, current_lines))
                  current_lines = []
              if due:
                  current_file = resolve_due_date_file(due, journal_file)
              else:
                  current_file = journal_file
                  if due_suffix and "📅" not in content:
                      content += due_suffix
              mark = (
                  inline_mark if inline_mark is not None
                  else (args.state if args.state else " ")
              )
          else:
              mark = inline_mark if inline_mark is not None else " "

          current_lines.append(
              format_output_line(depth, is_desc, content, mark)
          )

      if current_lines:
          blocks.append((current_file, current_lines))

      def write_block(path, content_to_write):
          os.makedirs(
              os.path.dirname(os.path.abspath(path)), exist_ok=True
          )
          if os.path.exists(path) and os.path.getsize(path) > 0:
              with open(path, "r") as f:
                  file_lines = f.readlines()

              marker_index = -1
              for i, line in enumerate(file_lines):
                  if TODO_MARKER in line:
                      marker_index = i
                      break

              if marker_index != -1:
                  file_lines.insert(marker_index + 1, content_to_write)
                  with open(path, "w") as f:
                      f.writelines(file_lines)
              else:
                  needs_newline = not file_lines[-1].endswith("\n")
                  with open(path, "a") as f:
                      if needs_newline:
                          f.write("\n")
                      f.write(content_to_write)
          else:
              with open(path, "w") as f:
                  f.write(content_to_write)

      # Write to file(s)
      try:
          written_files = []
          for path, out_lines in blocks:
              write_block(path, "\n".join(out_lines) + "\n")
              if path not in written_files:
                  written_files.append(path)

          for path in written_files:
              print(f"Added todo to {path}")
      except Exception as e:
          print(f"Error writing to file: {e}", file=sys.stderr)
          sys.exit(1)


  if __name__ == "__main__":
      main()
''
