{ pkgs, ... }:

let
  jour = pkgs.writers.writePython3Bin "jour" { } ''
    import os
    import sys
    from datetime import datetime, timedelta
    import subprocess
    import argparse

    # Define the default editor
    DEFAULT_EDITOR = "nvim"


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
            "-p", "--program", type=str, default=DEFAULT_EDITOR,
            help="Program to open the journal with."
        )
        args = parser.parse_args()

        editor_to_use = args.program or DEFAULT_EDITOR

        if args.weekly:
            weekly_dir = os.getenv("JOURNAL_WEEKLY_PATH")
            if not weekly_dir:
                print(
                    "Error: JOURNAL_WEEKLY_PATH environment variable "
                    "is not set.",
                    file=sys.stderr
                )
                sys.exit(1)

            target_date = datetime.now() + timedelta(weeks=args.offset)
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

            target_date = datetime.now() + timedelta(days=args.offset)
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
  '';
in
{
  environment.systemPackages = [
    jour
  ];
}
