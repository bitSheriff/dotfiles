{ pkgs }:

pkgs.writers.writePython3Bin "todo" { } ''
  import os
  import re
  import sys
  import shlex
  import calendar
  import curses
  import datetime
  import argparse
  import subprocess
  import readline  # noqa: F401  (enables arrow-key/line editing for input())

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


  def format_output_line(depth, is_desc, content, mark=" "):
      if is_desc:
          indent = INDENT_UNIT * (depth + 1)
          return f"{indent}- {content}"
      indent = INDENT_UNIT * depth
      return f"{indent}- [{mark}] {content}"


  # Checklist state characters (the content of "[ ]"), matching
  # todo-list's VALID_STATES - kept in sync so both scripts agree on
  # what a checklist mark can mean.
  VALID_STATES = {
      " ": "open",
      "x": "done",
      "i": "event",
      "/": "in-progress",
      "-": "cancelled",
      "<": "delegated",
      ">": "forwarded",
  }


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


  def parse_inline_options(content):
      """Pull a leading "<...>" block of todo flags off content.

      Lets a single multi-line interactive entry (when `todo` is run
      with no task arguments) carry a date/state per typed line
      instead of all lines sharing whatever -d/-o/-t/-T/-s was given
      on the command line, e.g. "<-T> Buy milk" alongside "<-t> Call
      bank". Recognizes -d/--date, -o/--offset, -t/--today,
      -T/--tomorrow and -s/--state, same meaning/accepted values as
      the matching command-line flags above. The block, if present,
      must be the very first thing in content (callers run this
      after stripping any "-"/"." nesting markers via
      parse_prefixed_line) - its contents are shlex-split, so
      shell-style quoting works (e.g. "<-d 'next friday'>").

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
          if tok in ("-t", "--today"):
              options["today"] = True
              i += 1
          elif tok in ("-T", "--tomorrow"):
              options["tomorrow"] = True
              i += 1
          elif tok in ("-d", "--date"):
              if i + 1 >= len(tokens):
                  raise ValueError(f"{tok} needs a value")
              options["date"] = tokens[i + 1]
              i += 2
          elif tok in ("-o", "--offset"):
              if i + 1 >= len(tokens):
                  raise ValueError(f"{tok} needs a value")
              try:
                  options["offset"] = int(tokens[i + 1])
              except ValueError:
                  raise ValueError(f"{tok} value must be an integer")
              i += 2
          elif tok in ("-s", "--state"):
              if i + 1 >= len(tokens):
                  raise ValueError(f"{tok} needs a value")
              state = tokens[i + 1].lower()
              if len(state) != 1 or state not in VALID_STATES:
                  valid = ", ".join(f"{s!r}" for s in VALID_STATES)
                  raise ValueError(
                      f"{tok} value must be one of: {valid}"
                  )
              options["state"] = state
              i += 2
          else:
              raise ValueError(f"unknown inline option {tok!r}")
      return options, rest


  def resolve_inline_due_date(options):
      """Resolve a "YYYY-MM-DD" due date from a parsed inline-options
      dict, using the same flag precedence as the command-line date
      flags (-d > -o > -T > -t). Returns None if none of date/
      offset/tomorrow/today was given.
      """
      today = datetime.date.today()
      if "date" in options:
          return parse_date(options["date"]).strftime("%Y-%m-%d")
      if "offset" in options:
          return (
              today + datetime.timedelta(days=options["offset"])
          ).strftime("%Y-%m-%d")
      if options.get("tomorrow"):
          return (today + datetime.timedelta(days=1)).strftime("%Y-%m-%d")
      if options.get("today"):
          return today.strftime("%Y-%m-%d")
      return None


  def resolve_due_date_file(due, fallback_path):
      """Return the daily journal file a \U0001F4C5 due date should
      land in: that date's own file if it exists (or the date is
      today), else today's file. Returns fallback_path unchanged if
      JOURNAL_DAILY_PATH isn't set (e.g. -f/--file or -w/--weekly
      contexts with no daily journal to redirect into).
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
      parse_inline_options) out of content and into the shape the
      output-line builder expects: a resolved due date is appended
      as a \U0001F4C5 emoji tag (unless content already carries one,
      in which case it's left alone), and an explicit -s/--state
      becomes the returned mark character.

      Returns (content, mark, due); mark is None if no -s/--state
      was given (callers should leave the existing/default mark
      alone in that case, rather than stomping it with " "); due is
      the resolved "YYYY-MM-DD" date, or None if no date/offset/
      today/tomorrow flag was given - pass it to
      resolve_due_date_file() to find which file the todo should
      actually land in. Raises ValueError if content carries
      inline options but is_desc (notes have no state/due
      semantics), or if the options themselves fail to parse (see
      parse_inline_options).
      """
      options, content = parse_inline_options(content)
      if not options:
          return content, None, None
      if is_desc:
          raise ValueError("inline options aren't supported on notes")
      due = resolve_inline_due_date(options)
      if due and "\U0001F4C5" not in content:
          content = f"{content} \U0001F4C5 {due}"
      return content, options.get("state"), due


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
                  "Ctrl+C to cancel). A leading \"<...>\" on a line "
                  "(e.g. \"<-T> Buy milk\") sets that todo's own "
                  "date/state, same flags as -d/-o/-t/-T/-s:"
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
