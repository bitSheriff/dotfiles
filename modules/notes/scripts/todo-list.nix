{ pkgs, todoCommon }:

pkgs.writers.writePython3Bin "todo-list" { libraries = [ todoCommon ]; } ''
  import os
  import re
  import sys
  import curses
  import datetime
  import argparse
  import subprocess
  from todo_common import (
      INDENT_UNIT, TODO_MARKER, VALID_STATES, PRIORITY_SYMBOLS,
      parse_prefixed_line, format_output_line, parse_date,
      resolve_due_date_file, apply_inline_options, normalize_state,
      add_shared_arguments, select_file_with_fzf, pick_calendar_date,
  )

  # Sentinel for -f/--file given with no argument, meaning "let me
  # pick the file interactively with fzf" (see select_file_with_fzf).
  FZF_SELECT = object()

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

      for emoji, name in PRIORITY_SYMBOLS:
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
      """Strip priority off and format the remaining task metadata
      for display. Priority gets its own visual treatment (the whole
      todo text is colored by priority, see PRIORITY_COLOR_ANSI/
      TUI_PRIORITY_COLOR) instead of a '(priority high)' suffix.
      """
      if not meta:
          return ""
      parts = []
      for field in TASK_FIELD_DISPLAY_ORDER:
          if field == "priority" or field not in meta:
              continue
          if field == "due" and meta.get("due_implied"):
              # Implicit due dates (every open todo in a daily journal
              # defaults to that day) aren't worth displaying - they're
              # true for virtually every todo and add no information.
              continue
          parts.append(f"{field} {meta[field]}")
      return " (" + ", ".join(parts) + ")" if parts else ""


  # Priority -> ANSI color code (plain output) / curses (pair, extra
  # attr) (--tui), used to color a todo's whole text by priority:
  # highest/high in red (highest also bold), medium yellow, low cyan,
  # lowest just dimmed.
  PRIORITY_COLOR_ANSI = {
      "highest": "1;31",
      "high": "31",
      "medium": "33",
      "low": "36",
      "lowest": "2",
  }


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
      implicitly due on that journal's own day - or, if it has a
      \u23F3 scheduled date and/or a \U0001F6EB start date later than
      that day, on whichever of those is later instead (a due date
      can never be implied earlier than when the todo is scheduled/
      allowed to start; between the two, scheduled wins if both are
      set). Mutates nodes in place (recursing into sub-todos) and
      marks defaulted entries with meta["due_implied"] = True so
      display/filtering can tell them apart from an explicit due
      date. Calendar events ("- [i] ...") are skipped - they aren't
      "due" on any particular day, they're always shown.
      """
      for n in nodes:
          if not n.get("is_event") and "due" not in n["meta"]:
              activation = n["meta"].get("scheduled") or n["meta"].get("start")
              n["meta"]["due"] = max(date_str, activation or date_str)
              n["meta"]["due_implied"] = True
          apply_implicit_due_dates(n["children"], date_str)


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
  NOT_DONE_DUE_STATES = (" ", ">", "/")


  def effective_activation_date(meta):
      """The date from which a todo should be considered relevant
      for --overdue/--all purposes: its \U0001F4C5 due date if set
      (daily journal todos always have one by this point - see
      apply_implicit_due_dates), otherwise its \u23F3 scheduled date,
      otherwise its \U0001F6EB start date, otherwise None (never
      shown). Scheduled takes priority over start when both are set
      but there's no due date - this only matters outside a daily
      journal, where apply_implicit_due_dates never runs so due can
      genuinely be absent.
      """
      return meta.get("due") or meta.get("scheduled") or meta.get("start")


  def filter_due_today(nodes, today_str):
      """Keep not-done todos relevant today or overdue, plus ancestors.

      A todo matches if its state is open (" "), forwarded (">") or
      in-progress ("/") and its effective activation date (due, else
      scheduled, else start - see effective_activation_date) is
      today or earlier (ISO YYYY-MM-DD strings sort chronologically,
      so a plain string comparison is enough). A daily journal todo
      with no explicit due date gets one implicitly (see
      apply_implicit_due_dates), so this still "just works" there;
      outside a daily journal (e.g. --all scanning the vault) a todo
      needs an explicit due/scheduled/start date to ever show up
      here, since there's nothing to imply one from. Note that
      becoming visible via scheduled/start rather than due doesn't
      mean "overdue" in the urgent sense - just "now relevant, no
      longer hidden"; only an actual due date in the past carries
      that connotation, and that distinction is left to the reader.
      Calendar events ("- [i] ...") never match here - they aren't
      "not done"/overdue, they're just appointments. Ancestors of a
      matching todo are kept (without being considered matches
      themselves) purely to preserve context; todos/branches with no
      matching descendant are dropped.
      """
      result = []
      for n in nodes:
          activation = effective_activation_date(n.get("meta", {}))
          matches = (
              n.get("state") in NOT_DONE_DUE_STATES
              and activation is not None and activation <= today_str
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


  def get_raw_task_text(path, line_no):
      """Return the raw, unparsed text of one checklist line (i.e.
      everything after "- [mark] ", emoji metadata and all - the
      same thing extract_task_metadata() would strip apart). Used
      by --tui's "e" edit so editing starts from exactly what's on
      disk rather than from the already-cleaned node["text"].
      Returns None if the line doesn't exist or isn't a checklist
      line (e.g. file changed concurrently).
      """
      with open(path) as f:
          lines = f.readlines()

      idx = line_no - 1
      if not (0 <= idx < len(lines)):
          return None

      line = lines[idx].rstrip("\n")
      m = CHECKLIST_RE.match(line)
      if not m:
          return None
      return m.group("text")


  def set_todo_text(path, line_no, new_text):
      """Overwrite the text portion of one checklist line (i.e.
      everything after "- [mark] ") on the given 1-indexed line.
      Indentation and the mark character are left untouched, as is
      every other line in the file. Used by --tui's "e" key to edit
      a todo's text in place. Returns True on success, False if the
      line doesn't exist or isn't a checklist line anymore (e.g.
      file changed concurrently).
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

      start, end = m.span("text")
      lines[idx] = line[:start] + new_text + line[end:] + eol

      with open(path, "w") as f:
          f.writelines(lines)
      return True


  def leading_indent_depth(line):
      stripped = line.lstrip(" ")
      return (len(line) - len(stripped)) // len(INDENT_UNIT)


  def find_insert_index(lines, node_line, node_depth):
      """Return the 0-indexed position right after the full subtree
      (children and notes) of the todo on 1-indexed node_line at
      node_depth - i.e. where a new sibling-or-deeper line should
      be inserted so it lands below that todo's existing content.
      Mirrors the blank-line/dedent block-termination rules used by
      parse_journal_todos.
      """
      idx = node_line  # 0-indexed line right after the node's own line
      n = len(lines)
      while idx < n:
          raw = lines[idx].rstrip("\n")
          if not raw.strip():
              break
          if leading_indent_depth(lines[idx]) <= node_depth:
              break
          idx += 1
      return idx


  def insert_todo_line(
      path, node_line, node_depth, new_depth, is_desc, content, mark=" ",
  ):
      """Insert a new checklist todo or note line into the journal
      file, positioned right after the full subtree of the todo
      currently on node_line (1-indexed, at node_depth) - used by
      --tui's "a" key. new_depth is the nesting depth of the todo
      this line is attached to (node_depth plus however many "-"
      markers were typed - see parse_prefixed_line); for a note
      (is_desc), the line itself is indented one level deeper than
      that, matching todo.nix's format_output_line. Returns the
      1-indexed line number of the newly inserted line.
      """
      with open(path) as f:
          lines = f.readlines()

      idx = find_insert_index(lines, node_line, node_depth)
      new_line = format_output_line(new_depth, is_desc, content, mark) + "\n"

      lines.insert(idx, new_line)
      with open(path, "w") as f:
          f.writelines(lines)
      return idx + 1


  def insert_root_todo_line(path, new_depth, is_desc, content, mark=" "):
      """Insert a new top-level checklist todo or note line into
      path, creating the file (and parent directories) if it
      doesn't exist yet. Used by --tui's "a" key when a section
      has no existing todos to anchor off of (e.g. an empty daily
      journal) - mirrors how the `todo` command appends new
      entries (after %%insert_todo%%, if present, else at the end
      of the file). Returns the 1-indexed line number of the
      inserted line.
      """
      os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
      new_line = format_output_line(new_depth, is_desc, content, mark) + "\n"

      if os.path.exists(path) and os.path.getsize(path) > 0:
          with open(path) as f:
              lines = f.readlines()
          marker_index = next(
              (i for i, line in enumerate(lines) if TODO_MARKER in line),
              None,
          )
          if marker_index is not None:
              lines.insert(marker_index + 1, new_line)
              line_no = marker_index + 2
          else:
              if not lines[-1].endswith("\n"):
                  lines[-1] += "\n"
              lines.append(new_line)
              line_no = len(lines)
          with open(path, "w") as f:
              f.writelines(lines)
      else:
          with open(path, "w") as f:
              f.write(new_line)
          line_no = 1

      return line_no


  def show_message(stdscr, y, text):
      """Flash text on screen row y (reverse video) until any key is
      pressed. Used to surface inline-option parse errors from the
      a/e keys without tearing down the browser.
      """
      _, max_x = stdscr.getmaxyx()
      stdscr.move(y, 0)
      stdscr.clrtoeol()
      stdscr.addstr(y, 0, text[:max_x - 1], curses.A_BOLD | curses.A_REVERSE)
      stdscr.refresh()
      stdscr.getch()


  def edit_line_input(stdscr, y, initial="", prompt="Edit: "):
      """Run a small inline text editor on screen row y, pre-filled
      with initial, supporting the usual editing keys (left/right/
      home/end/backspace/delete). Returns the edited string on
      Enter, or None if the user cancelled with Esc.
      """
      max_y, max_x = stdscr.getmaxyx()
      buf = list(initial)
      pos = len(buf)
      curses.curs_set(1)
      try:
          while True:
              stdscr.move(y, 0)
              stdscr.clrtoeol()
              text = "".join(buf)
              avail = max_x - len(prompt) - 1
              # Keep the cursor's position visible if the text is
              # wider than the screen.
              view_start = max(0, pos - avail) if avail > 0 else 0
              stdscr.addstr(y, 0, prompt, curses.A_BOLD)
              visible = text[view_start:view_start + max(avail, 0)]
              stdscr.addstr(y, len(prompt), visible)
              stdscr.move(y, min(len(prompt) + pos - view_start, max_x - 1))
              stdscr.refresh()

              try:
                  ch = stdscr.get_wch()
              except curses.error:
                  continue

              if ch in ("\n", "\r") or ch == curses.KEY_ENTER:
                  return "".join(buf)
              elif ch == chr(27):
                  return None
              elif ch in ("\x7f", "\b") or ch == curses.KEY_BACKSPACE:
                  if pos > 0:
                      del buf[pos - 1]
                      pos -= 1
              elif ch == curses.KEY_DC:
                  if pos < len(buf):
                      del buf[pos]
              elif ch == curses.KEY_LEFT:
                  pos = max(0, pos - 1)
              elif ch == curses.KEY_RIGHT:
                  pos = min(len(buf), pos + 1)
              elif ch in (curses.KEY_HOME, 1):  # 1 = Ctrl-A
                  pos = 0
              elif ch in (curses.KEY_END, 5):  # 5 = Ctrl-E
                  pos = len(buf)
              elif isinstance(ch, str) and ch.isprintable():
                  buf.insert(pos, ch)
                  pos += 1
      finally:
          curses.curs_set(0)


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
          suffix = c("2", format_task_metadata(n.get("meta", {})))
          # Priority colors the whole todo text, but only for the
          # "still active" states - done/cancelled/delegated already
          # fade/strike their text to signal they're settled, and
          # that de-emphasis matters more than their old priority.
          pcolor = PRIORITY_COLOR_ANSI.get(n.get("meta", {}).get("priority"))
          active_text = c(pcolor, n["text"]) if pcolor else n["text"]
          if n.get("is_event"):
              box = c("36", "[i]")
              text = active_text + suffix
          elif n.get("in_progress"):
              box = c("33", "[/]")
              text = active_text + suffix
          elif n.get("cancelled"):
              box = c("31", "[-]")
              text = c("31;9", n["text"]) + suffix
          elif n.get("delegated"):
              box = c("35", "[<]")
              text = c("35;9", n["text"]) + suffix
          elif n.get("forwarded"):
              box = c("34", "[>]")
              text = active_text + suffix
          elif n["done"]:
              box = c("32", "[x]")
              text = c("2;9", n["text"]) + suffix
          else:
              box = "[ ]"
              text = active_text + suffix
          print(f"{indent}- {box} {text}")
          for note in n["notes"]:
              note_indent = INDENT_UNIT * (depth + 1)
              print(f"{note_indent}- {c('2;3', note)}")
          print_todo_tree(n["children"], depth + 1)


  def output_sections(
      sections, empty_message, args, header_fn=None, refresh_paths=None,
      fallback_path=None,
  ):
      """Print sections, or hand them to the interactive --tui browser.

      sections is a list of (path, todos) pairs (todos possibly
      empty - those are skipped). header_fn defaults to
      print_file_header (short, bold basename); pass print instead
      for a full-path header (e.g. --all). refresh_paths, if given,
      is a callable returning a fresh path list - used by --tui's
      "r" key to pick up brand new journal files that didn't exist
      (or had no matching todos) when the browser was launched.

      With --tui, an empty result doesn't just print empty_message
      and quit - there'd be no way to add a new todo. If
      fallback_path is given, the browser opens on that file
      instead (showing an empty, but "a"-addable, section);
      otherwise (or if even that has nothing to show) it falls
      back to printing empty_message.
      """
      header_fn = header_fn or print_file_header
      non_empty = [(path, todos) for path, todos in sections if todos]

      if args.tui:
          if non_empty:
              run_tui([path for path, _ in non_empty], args, refresh_paths)
              return
          if fallback_path:
              run_tui([fallback_path], args, refresh_paths)
              return
          print(empty_message)
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


  # Priority -> (curses color pair, extra attr), reusing the state
  # color pairs init_pair'd below (1=green..6=blue). Only applied to
  # the "still active" states (open/event/in-progress/forwarded,
  # see TUI_NEUTRAL_STATES below) - done/cancelled/delegated keep
  # their own color, their settled state matters more than priority.
  TUI_PRIORITY_COLOR = {
      "highest": (4, curses.A_BOLD),  # red, bold
      "high": (4, 0),                 # red
      "medium": (3, 0),               # yellow
      "low": (2, 0),                  # cyan
      "lowest": (0, curses.A_DIM),    # no color, just dimmed
  }

  TUI_NEUTRAL_STATES = (" ", ">", "/", "i")


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
      original path list - except that rediscovered files are kept
      only if they still have matching todos, or if they're today's
      daily journal (always kept, even empty, so there's somewhere
      to add a new todo for today).
      """
      collapsed = {}  # (path, line) -> True if collapsed

      def build_rows():
          rows = []
          for path in paths:
              todos = get_filtered_todos(path, args)
              # Always keep the header, even with no todos - with
              # --tui that's the only anchor left to add a new
              # todo to (see _is_selectable/the "a" handler below).
              rows.append({"type": "header", "path": path, "empty": not todos})
              if todos:
                  _add_rows(rows, path, todos, 0)
          return rows

      def _is_selectable(r):
          return r["type"] == "todo" or (
              r["type"] == "header" and r.get("empty")
          )

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
              if _is_selectable(r):
                  return i
          return 0

      def last_selectable(rows):
          for i in range(len(rows) - 1, -1, -1):
              if _is_selectable(rows[i]):
                  return i
          return 0

      def move(rows, pos, delta):
          i = pos
          while True:
              i += delta
              if i < 0 or i >= len(rows):
                  return pos
              if _is_selectable(rows[i]):
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
          while i < len(rows) and not _is_selectable(rows[i]):
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
          if _is_selectable(rows[pos]):
              return pos
          for i in range(pos, len(rows)):
              if _is_selectable(rows[i]):
                  return i
          for i in range(pos, -1, -1):
              if _is_selectable(rows[i]):
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
                  if row.get("empty"):
                      label += " (no todos - press a to add one)"
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
                  pair = TUI_STATE_COLOR_PAIR.get(n["state"])
                  attr = curses.color_pair(pair) if pair else 0
                  priority = n.get("meta", {}).get("priority")
                  if priority and n["state"] in TUI_NEUTRAL_STATES:
                      pair_num, pextra = TUI_PRIORITY_COLOR.get(priority, (0, 0))
                      attr = (curses.color_pair(pair_num) if pair_num else 0)
                      attr |= pextra
                  if n["done"]:
                      attr |= curses.A_DIM
                  text = f"{indent}- {box} {n['text']}{suffix}{marker}"
                  stdscr.addstr(i, 0, text[:max_x - 1], attr | reverse)

          footer = (
              "j/k move  h/l collapse/expand  n/p next/prev day  "
              "g/G top/bottom  space/x/i//-/</> set state  e edit  "
              "a add  o open in editor  D toggle done  r reload  q quit"
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
                  if row["type"] == "todo":
                      rkey = row["key"]
                      if row["node"]["children"] and not collapsed.get(rkey):
                          collapsed[rkey] = True
                          rows = build_rows()
                          sel = find_key(rows, rkey, sel)
                      else:
                          sel = parent_row(rows, sel)
              elif key in (ord("l"), curses.KEY_RIGHT):
                  row = rows[sel]
                  if row["type"] == "todo":
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
                  if row["type"] == "todo":
                      mark = " " if key == ord(" ") else chr(key)
                      set_todo_mark(row["path"], row["node"]["line"], mark)
                      rows = build_rows()
                      if not rows:
                          return
                      sel = nearest_selectable(rows, sel)
              elif key == ord("e"):
                  row = rows[sel]
                  if row["type"] == "todo":
                      rkey = row["key"]
                      raw_text = get_raw_task_text(
                          row["path"], row["node"]["line"]
                      )
                      if raw_text is None:
                          raw_text = row["node"]["text"]
                      max_y, _ = stdscr.getmaxyx()
                      new_text = edit_line_input(stdscr, max_y - 1, raw_text)
                      stdscr.keypad(True)
                      if new_text is not None and new_text.strip() != "":
                          try:
                              content, mark, _due, _file = (
                                  apply_inline_options(
                                      new_text.strip(), False
                                  )
                              )
                          except ValueError as e:
                              show_message(stdscr, max_y - 1, f"Error: {e}")
                              content = None
                          if content:
                              set_todo_text(
                                  row["path"], row["node"]["line"], content
                              )
                              if mark is not None:
                                  set_todo_mark(
                                      row["path"], row["node"]["line"], mark
                                  )
                              rows = build_rows()
                              if not rows:
                                  return
                              sel = find_key(rows, rkey, sel)
              elif key == ord("a"):
                  row = rows[sel]
                  max_y, _ = stdscr.getmaxyx()
                  raw_input = edit_line_input(
                      stdscr, max_y - 1, "", prompt="Add: "
                  )
                  stdscr.keypad(True)
                  if raw_input is not None and raw_input.strip():
                      markers_depth, is_desc, content = parse_prefixed_line(
                          raw_input.strip()
                      )
                      try:
                          content, mark, due, inline_file = (
                              apply_inline_options(content, is_desc)
                          )
                      except ValueError as e:
                          show_message(stdscr, max_y - 1, f"Error: {e}")
                          content = None
                      if content:
                          mark = mark if mark is not None else " "
                          # A resolved due date (or -f/-w) may redirect
                          # the new todo into a different file than
                          # the one currently browsed (see
                          # resolve_due_date_file/resolve_inline_file)
                          # - same as todo's own -d/-o/-f/-w file
                          # selection. There's then nothing in that
                          # other file to anchor off of, so it's
                          # always a root-level insert.
                          path = row["path"]
                          redirected = False
                          if inline_file:
                              path = inline_file
                              redirected = path != row["path"]
                              if path not in paths:
                                  paths.append(path)
                          elif due:
                              path = resolve_due_date_file(due, row["path"])
                              redirected = path != row["path"]
                              if path not in paths:
                                  paths.append(path)

                          if row["type"] == "header" or redirected:
                              new_depth = markers_depth
                              new_line_no = insert_root_todo_line(
                                  path, new_depth, is_desc, content, mark,
                              )
                          else:
                              new_depth = row["depth"] + markers_depth
                              new_line_no = insert_todo_line(
                                  path, row["node"]["line"], row["depth"],
                                  new_depth, is_desc, content, mark,
                              )
                          rkey = row.get("key") if not redirected else None
                          rows = build_rows()
                          if not rows:
                              return
                          if is_desc:
                              sel = (
                                  find_key(rows, rkey, sel) if rkey
                                  else nearest_selectable(rows, sel)
                              )
                          else:
                              sel = find_key(rows, (path, new_line_no), sel)
              elif key == ord("o"):
                  row = rows[sel]
                  if row["type"] == "todo":
                      editor = os.environ.get("EDITOR", args.editor)
                      curses.def_prog_mode()
                      curses.endwin()
                      try:
                          subprocess.run(
                              [editor, f"+{row['node']['line']}", row["path"]]
                          )
                      except FileNotFoundError:
                          pass
                      curses.reset_prog_mode()
                      stdscr.keypad(True)
                      rkey = row["key"]
                      rows = build_rows()
                      if not rows:
                          return
                      sel = find_key(rows, rkey, sel)
                      stdscr.clear()
              elif key == ord("D"):
                  args.done = not args.done
                  rows = build_rows()
                  if not rows:
                      return
                  sel = nearest_selectable(rows, sel)
              elif key == ord("r"):
                  rkey = rows[sel].get("key") if rows else None
                  if refresh_paths is not None:
                      today = datetime.date.today()
                      paths[:] = [
                          p for p in refresh_paths()
                          if get_filtered_todos(p, args)
                          or infer_journal_date(p) == today
                      ]
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
      add_shared_arguments(
          parser, ["weekly", "offset", "date", "calendar", "file"],
          weekly={"help": "Read the weekly journal instead of the daily one."},
          offset={
              "help": "Offset in days (daily) or weeks (weekly) from today.",
          },
          date={
              "help": (
                  "Date for the daily journal (weekday name, 'today', "
                  "'tomorrow', 'yesterday', or a possibly-partial "
                  "YYYY-MM-DD date). Ignored with --weekly."
              ),
          },
          calendar={
              "help": (
                  "Interactively pick the date from a calendar (weeks "
                  "start on Monday), instead of -d/--date. --offset "
                  "still applies relative to the picked date."
              ),
          },
          file={
              "const": FZF_SELECT,
              "help": (
                  "Read this file directly instead of resolving a "
                  "journal file. Ignored with --all. If given with "
                  "no argument, pick the file interactively with fzf "
                  "from $NOTES_DIR."
              ),
          },
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
              "instead of a single journal file. Ignores -w/-o/-d/-f. "
              "Defaults to the same overdue/due-today filtering as "
              "--overdue (otherwise overwhelming); todos outside a "
              "daily journal file need an explicit \U0001F4C5 due date "
              "to show up, since there's no implicit due date for "
              "them. Pass --done or --state to see everything/a "
              "specific state instead."
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
      add_shared_arguments(
          parser, ["state"],
          state={
              "help": (
                  "Only show todos with this checklist state - the "
                  "character inside \"[ ]\": " + ", ".join(
                      f"{s!r} ({name})"
                      for s, name in VALID_STATES.items()
                  ) + ". Overrides --done/--overdue."
              ),
          },
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
              "line), e edits a todo's text in place (Enter to save, "
              "Esc to cancel), a adds a new todo below the selected "
              "one - prefix the text with \"-\" per extra nesting level "
              "(e.g. \"- foo\" for a child) and/or \".\" to add a note "
              "instead of a todo (e.g. \"-. note\"), same syntax as "
              "todo's multi-line input. A leading \"<...>\" on the "
              "typed text (e.g. \"<-o 1> Buy milk\") is parsed as "
              "inline flags instead of being added to the title - "
              "-d/--date, -o/--offset, -t/--today, -T/--tomorrow set "
              "a \U0001F4C5 due date, -s/--state sets the checklist "
              "mark, -p/--priority (1 highest .. 5 lowest) sets an "
              "Obsidian Tasks priority emoji, same values as "
              "todo's/todo-list's own flags. "
              "D toggles showing done todos, "
              "r reloads every "
              "file from disk (picking up todos added elsewhere, and "
              "newly created journal files - empty days are dropped "
              "again except today's, which stays so you can still add "
              "to it), q quits. With no other "
              "file-selection flag, defaults to the same overdue/"
              "due-today scan as a bare --overdue. Works with --all "
              "too, browsing the (also overdue-filtered by default) "
              "vault-wide scan. Not supported with --open."
          )
      )
      args = parser.parse_args()

      if args.file is FZF_SELECT:
          args.file = select_file_with_fzf()

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
          try:
              args.state = normalize_state(args.state)
          except ValueError as e:
              print(f"Error: {e}", file=sys.stderr)
              sys.exit(1)

      if args.open and args.all:
          print("Error: --open is not supported with --all.", file=sys.stderr)
          sys.exit(1)

      if args.all and not args.overdue and not args.done and args.state is None:
          # --all scans the whole vault, which is overwhelming without
          # a filter - default to the same overdue/due-today criteria
          # as --overdue: daily-journal todos use their implicit due
          # date, every other file's todos need an explicit due date
          # to be considered (no implicit due makes sense outside a
          # daily journal). Explicit --done/--state/--overdue override
          # this default.
          args.overdue = True

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

          today_file = os.path.join(
              daily_dir, f"{datetime.date.today().strftime('%Y-%m-%d')}.md"
          )
          output_sections(
              sections,
              f"No {scope_message(args)} found between "
              f"{start_date.strftime('%Y-%m-%d')} and "
              f"{end_date.strftime('%Y-%m-%d')}",
              args, fallback_path=today_file,
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
          today_file = os.path.join(
              daily_dir, f"{datetime.date.today().strftime('%Y-%m-%d')}.md"
          )
          output_sections(
              sections, f"No {scope_message(args)} found in {daily_dir}",
              args,
              refresh_paths=lambda: find_daily_journal_files(daily_dir),
              fallback_path=today_file,
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
          daily_dir = os.getenv("JOURNAL_DAILY_PATH")
          fallback_path = (
              os.path.join(
                  daily_dir,
                  f"{datetime.date.today().strftime('%Y-%m-%d')}.md",
              ) if daily_dir else None
          )
          output_sections(
              sections,
              f"No {scope_message(args)} found in vault ({notes_dir})",
              args, header_fn=print,
              refresh_paths=lambda: find_vault_markdown_files(notes_dir),
              fallback_path=fallback_path,
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
          if not args.tui:
              print(
                  f"No journal file found at {target_file}",
                  file=sys.stderr,
              )
              sys.exit(1)
          todos = []
      else:
          todos = get_filtered_todos(target_file, args)

      output_sections(
          [(target_file, todos)],
          f"No {scope_message(args)} found in {target_file}",
          args, fallback_path=target_file,
      )


  if __name__ == "__main__":
      main()
''
