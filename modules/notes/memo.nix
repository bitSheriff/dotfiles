{ pkgs, ... }:

let
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
in
{
  environment.systemPackages = [
    memo
    memo-gui
  ];
}
