{ pkgs }:

pkgs.writers.writePython3Bin "jour" { } ''
    import calendar
    import curses
    import os
    import sys
    from datetime import datetime, timedelta
    import subprocess
    import argparse

    # Define the default editor
    DEFAULT_EDITOR = "nvim"

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
        weeks = cal.monthdayscalendar(
            cursor_date.year, cursor_date.month
        )
        today = datetime.now().date()

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
                    day_date = cursor_date.replace(day=day).date()
                    if day_date == cursor_date.date():
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

        Returns a ``datetime`` for the selected day, or ``None`` if the
        user cancelled.
        """

        def _inner(stdscr):
            curses.curs_set(0)
            stdscr.keypad(True)
            cursor_date = initial_date or datetime.now()

            while True:
                draw_calendar(stdscr, cursor_date)
                key = stdscr.getch()

                if key in (curses.KEY_LEFT, ord("h")):
                    cursor_date -= timedelta(days=1)
                elif key in (curses.KEY_RIGHT, ord("l")):
                    cursor_date += timedelta(days=1)
                elif key in (curses.KEY_UP, ord("k")):
                    cursor_date -= timedelta(days=7)
                elif key in (curses.KEY_DOWN, ord("j")):
                    cursor_date += timedelta(days=7)
                elif key in (ord("p"), curses.KEY_PPAGE):
                    cursor_date = add_months(cursor_date, -1)
                elif key in (ord("n"), curses.KEY_NPAGE):
                    cursor_date = add_months(cursor_date, 1)
                elif key == ord("t"):
                    cursor_date = datetime.now()
                elif key in (ord("\n"), curses.KEY_ENTER, ord(" ")):
                    return cursor_date
                elif key in (27, ord("q")):
                    return None

        return curses.wrapper(_inner)


    def parse_date(value):
        """Parse a date, filling in the parts that were left out.

        Accepts YYYY-MM-DD, MM-DD (current year) and DD (current
        year and month). Raises ValueError on anything else.
        """
        today = datetime.now()
        parts = value.split("-")
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
        return datetime.strptime(f"{year}-{month}-{day}", "%Y-%m-%d")


    def main():
        parser = argparse.ArgumentParser(description="Open journal file.")
        parser.add_argument(
            "-w", "--weekly", action="store_true",
            help="Open weekly journal instead of daily."
        )
        parser.add_argument(
            "-o", "--offset", type=int, default=0,
            help=(
                "Offset. In days for daily, weeks for weekly. "
                "Positive for future, negative for past."
            )
        )
        parser.add_argument(
            "-e", "--editor", type=str, default=DEFAULT_EDITOR,
            help="Editor to open the journal with."
        )
        parser.add_argument(
            "-d", "--date", type=str, default=None,
            help=(
                "Date to open the journal for. Accepts YYYY-MM-DD, "
                "MM-DD (current year), or DD (current year and "
                "month). Overrides --offset."
            )
        )
        parser.add_argument(
            "-c", "--calendar", action="store_true",
            help=(
                "Interactively pick the date from a calendar "
                "(weeks start on Monday). Overrides --date and "
                "--offset."
            )
        )
        args = parser.parse_args()

        base_date = datetime.now()
        if args.calendar:
            selected = run_calendar(base_date)
            if selected is None:
                print("No date selected.", file=sys.stderr)
                sys.exit(1)
            base_date = selected
        elif args.date:
            try:
                base_date = parse_date(args.date)
            except ValueError:
                print(
                    f"Error: Invalid date '{args.date}'. Expected "
                    "YYYY-MM-DD, MM-DD (current year) or DD "
                    "(current year and month).",
                    file=sys.stderr
                )
                sys.exit(1)

        editor_to_use = args.editor or DEFAULT_EDITOR

        if args.weekly:
            weekly_dir = os.getenv("JOURNAL_WEEKLY_PATH")
            if not weekly_dir:
                print(
                    "Error: JOURNAL_WEEKLY_PATH environment variable "
                    "is not set.",
                    file=sys.stderr
                )
                sys.exit(1)

            target_date = base_date + timedelta(weeks=args.offset)
            iso_year, iso_week, _ = target_date.isocalendar()
            filename = f"{iso_year}-W{iso_week:02d}.md"
            journal_file = os.path.join(weekly_dir, filename)
        else:
            daily_dir = os.getenv("JOURNAL_DAILY_PATH")
            if not daily_dir:
                print(
                    "Error: JOURNAL_DAILY_PATH environment variable "
                    "is not set.",
                    file=sys.stderr
                )
                sys.exit(1)

            target_date = base_date + timedelta(days=args.offset)
            formatted_date = target_date.strftime("%Y-%m-%d")
            journal_file = os.path.join(daily_dir, f"{formatted_date}.md")

        # Open the file with the chosen editor
        try:
            subprocess.run([editor_to_use, journal_file])
        except FileNotFoundError:
            print(
                f"Error: Editor '{editor_to_use}' not found.",
                file=sys.stderr
            )
            sys.exit(1)


    if __name__ == "__main__":
        main()
  ''
