
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
        Opens the daily journal file with the given editor or the default editor.

        Parameters:
        - offset (int): The day offset. Positive for future, negative for past. Defaults to 0 (today).
        - editor (str): The editor to use. If None, the default editor will be used.
        """
        # Determine the editor to use
        editor_to_use = editor or DEFAULT_EDITOR

        # Define the NOTES_DIR environment variable
        daily_dir = os.getenv("JOURNAL_DAILY_PATH")
        if not daily_dir:
            raise EnvironmentError("JOURNAL_DAILY_PATH environment variable is not set.")

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
            print("    open_journal               # Opens today's journal with the default editor")
            print("    open_journal nvim          # Opens today's journal with nvim")
            print("    open_journal -1 nvim       # Opens yesterday's journal with nvim")
            print("    open_journal +1 nvim       # Opens tomorrow's journal with nvim")
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
in
{
  environment.systemPackages = with pkgs; [
    obsidian # the best note system
    daily
    notes
  ];
}
