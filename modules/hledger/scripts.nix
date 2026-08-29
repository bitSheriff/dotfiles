# The hledger helper scripts, as plain derivations.
#
# This file deliberately takes only `pkgs` and returns packages, so it can be
# consumed both by the NixOS module (./default.nix) and by the nix-on-droid
# configuration (../../hosts/android), which has no NixOS module system.
#
# Every script appends its own dependencies to PATH instead of relying on the
# surrounding environment, so they also work from a Termux-style bootstrap
# where the system PATH is nearly empty.
{ pkgs }:

let
  inherit (pkgs) lib;

  # Tools the scripts shell out to. Appended (not prepended) to PATH so an
  # interactive user's own binaries still win.
  runtimePath = lib.makeBinPath (
    with pkgs;
    [
      hledger
      gum
      fzf
      coreutils
      gnugrep
      gnused
    ]
  );

  # Wrap writeShellScriptBin so every script gets the PATH fallback. Scripts
  # that call a sibling script (hl-accounts) append it themselves.
  writeScript =
    name: text:
    pkgs.writeShellScriptBin name ''
      export PATH="$PATH:${runtimePath}"
      ${text}
    '';
in
rec {
  # Helper: collect accounts from a hledger file AND any sibling files that
  # share the same basename in the same directory (e.g. 2026SS.timeclock next
  # to 2026SS.timedot). timedot and timeclock syntaxes cannot be mixed in a
  # single hledger invocation, so each file is parsed on its own and the
  # results are merged, sorted and de-duplicated.
  #
  # Not meant to be used directly; it is a helper for the timeclock/timedot
  # add scripts to build a unified account list for gum/fzf selection.
  hl-accounts = pkgs.writeShellApplication {
    name = "hl-accounts";
    runtimeInputs = with pkgs; [
      hledger
      coreutils
    ];
    text = ''
      if [ $# -eq 0 ]; then
          echo "Usage: $0 <file>" >&2
          exit 1
      fi

      FILE="$1"

      DIR=$(dirname -- "$FILE")
      BASENAME=$(basename -- "$FILE")
      # Strip the final extension to get the shared basename (stem).
      STEM="''${BASENAME%.*}"

      # File extensions hledger knows how to parse.
      EXTENSIONS="journal timedot timeclock hledger ledger"

      {
          # Always include the given file itself.
          hledger -f "$FILE" accounts 2>/dev/null || true

          # Plus any sibling files sharing the same basename (stem).
          for ext in $EXTENSIONS; do
              candidate="$DIR/$STEM.$ext"
              # Skip the input file (already handled above) and missing files.
              [ "$candidate" = "$FILE" ] && continue
              if [ -f "$candidate" ]; then
                  hledger -f "$candidate" accounts 2>/dev/null || true
              fi
          done
      } | sort -u
    '';
  };

  timeclock-add = writeScript "timeclock-add" ''
    export PATH="$PATH:${lib.makeBinPath [ hl-accounts ]}"

    # Check if file argument is provided
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <file> [in|out|i|o] [account]"
        exit 1
    fi

    FILE="$1"
    ACTION_ARG="$2"
    ACCOUNT_ARG="$3"

    # Check if file exists
    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    ACTION=""
    ACCOUNT=""

    # Parse Action argument if provided
    if [ -n "$ACTION_ARG" ]; then
        case "$ACTION_ARG" in
            in|i) ACTION="i" ;;
            out|o) ACTION="o" ;;
            *) echo "Invalid action: $ACTION_ARG (use in/i or out/o)"; exit 1 ;;
        esac
    fi

    # Parse Account argument if provided
    if [ -n "$ACCOUNT_ARG" ]; then
        ACCOUNT="$ACCOUNT_ARG"
    fi

    # Interactive selection if needed
    if [ -z "$ACCOUNT" ] || [ -z "$ACTION" ]; then
        # Try to get existing accounts (from this file and its siblings),
        # suppress errors if file is empty/invalid
        EXISTING_ACCOUNTS=$(hl-accounts "$FILE" 2>/dev/null || true)

        if command -v gum >/dev/null 2>&1; then
            # Prompt for account if not provided
            if [ -z "$ACCOUNT" ]; then
                if [ -z "$EXISTING_ACCOUNTS" ]; then
                    ACCOUNT=$(gum input --placeholder "New file. Enter account name:")
                else
                    ACCOUNT=$(echo "$EXISTING_ACCOUNTS" | gum filter --no-strict --placeholder "Select or type account")
                fi
                if [ -z "$ACCOUNT" ]; then exit 0; fi
            fi

            # Prompt for action if not provided
            if [ -z "$ACTION" ]; then
                ACTION_SEL=$(printf "in\nout" | gum choose --header "Select action")
                if [ -z "$ACTION_SEL" ]; then exit 0; fi
                [ "$ACTION_SEL" == "in" ] && ACTION="i" || ACTION="o"
            fi
        elif command -v fzf >/dev/null 2>&1; then
            # Prompt for account if not provided
            if [ -z "$ACCOUNT" ]; then
                if [ -z "$EXISTING_ACCOUNTS" ]; then
                    printf "New file. Enter account name: "
                    read -r ACCOUNT
                else
                    # --print-query allows typing a new account not in the list. tail -1 grabs either the selection or the typed query.
                    ACCOUNT=$(echo "$EXISTING_ACCOUNTS" | fzf --header "Select account (or type new & press Enter)" --print-query | tail -1)
                fi
                if [ -z "$ACCOUNT" ]; then exit 0; fi
            fi

            # Prompt for action if not provided
            if [ -z "$ACTION" ]; then
                ACTION_SEL=$(printf "in\nout" | fzf --header "Select action")
                if [ -z "$ACTION_SEL" ]; then exit 0; fi
                [ "$ACTION_SEL" == "in" ] && ACTION="i" || ACTION="o"
            fi
        else
            if [ -z "$ACCOUNT" ] || [ -z "$ACTION" ]; then
                echo "Error: Missing arguments and neither gum nor fzf found for selection"
                exit 1
            fi
        fi
    fi

    # Get current date and time
    DATE=$(date +%Y-%m-%d)
    TIME=$(date +%H:%M)

    # Construct the entry: action date time account
    ENTRY=$(printf "%s %s %s %s" "$ACTION" "$DATE" "$TIME" "$ACCOUNT")

    # Append the entry to the file
    echo "$ENTRY" >>"$FILE"
  '';

  timedot-add = writeScript "timedot-add" ''
    export PATH="$PATH:${lib.makeBinPath [ hl-accounts ]}"

    # Check if file argument is provided
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <file> [date]"
        echo "  date: optional, ISO format (YYYY-MM-DD), defaults to today"
        exit 1
    fi

    FILE="$1"

    # Check if file exists
    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    # Optional second argument: date in ISO format (YYYY-MM-DD), defaults to today
    if [ -n "''${2:-}" ]; then
        if ! [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "Invalid date: $2 (expected ISO format YYYY-MM-DD)"
            exit 1
        fi
        DATE="$2"
    else
        DATE=$(date +%Y-%m-%d)
    fi

    # Get inputs using gum if available, otherwise fallback to fzf/read
    if command -v gum >/dev/null 2>&1; then
        # Select account using hledger (this file + siblings) and gum
        ACCOUNT=$(hl-accounts "$FILE" | gum filter --no-strict --placeholder "Select account")

        # Exit if no account selected (e.g., user pressed Esc)
        if [ -z "$ACCOUNT" ]; then
            exit 0
        fi

        # Ask for amount using gum
        AMOUNT=$(gum input --placeholder "Amount")

        # Exit if no amount entered
        if [ -z "$AMOUNT" ]; then
            exit 0
        fi

        # Ask for optional comment using gum
        COMMENT=$(gum input --placeholder "Comment (optional)")
    else
        # Fallback to fzf for account selection
        if command -v fzf >/dev/null 2>&1; then
            ACCOUNT=$(hl-accounts "$FILE" | fzf --header "Select account")
        else
            echo "Error: Neither gum nor fzf found for account selection"
            exit 1
        fi

        # Exit if no account selected
        if [ -z "$ACCOUNT" ]; then
            exit 0
        fi

        # Ask for amount using normal input
        read -p "Amount: " AMOUNT

        # Exit if no amount entered
        if [ -z "$AMOUNT" ]; then
            exit 0
        fi

        # Ask for optional comment using normal input
        read -p "Comment (optional): " COMMENT
    fi

    # Construct the entry: 4 spaces indent, account, 4+ spaces, amount
    # Using 40 characters for the account field to keep things somewhat aligned
    ENTRY=$(printf "    %-40s    %s" "$ACCOUNT" "$AMOUNT")

    # Add optional comment if provided
    if [ -n "$COMMENT" ]; then
        # Ensure comment starts with ;
        if [[ ! "$COMMENT" =~ ^\; ]]; then
            COMMENT="; $COMMENT"
        fi
        ENTRY=$(printf "%s    %s" "$ENTRY" "$COMMENT")
    fi

    # Find the line number of the date header
    LINE_NUM=$(grep -n "^$DATE" "$FILE" | cut -d: -f1)

    if [ -z "$LINE_NUM" ]; then
        # The date header does not exist yet. Rather than failing, create it at
        # the end of the file - but tell the user, so a typo in the file (or a
        # wrong file) does not silently grow a new day block.
        WARNING="Warning: date $DATE not found in $FILE - creating the date header"
        if command -v gum >/dev/null 2>&1; then
            gum style --foreground 3 "$WARNING" >&2
        else
            echo "$WARNING" >&2
        fi

        # Make sure the file ends with a newline and that a blank line separates
        # the new block from the previous one.
        if [ -s "$FILE" ]; then
            [ -n "$(tail -c 1 "$FILE")" ] && echo "" >>"$FILE"
            [ -n "$(tail -n 1 "$FILE")" ] && echo "" >>"$FILE"
        fi

        printf '%s\n%s\n' "$DATE" "''${ENTRY}" >>"$FILE"
        exit 0
    fi

    # Find the first blank line after the date header to determine insertion point
    # We start searching from the date header line itself
    OFFSET=$(tail -n +$LINE_NUM "$FILE" | grep -n "^$" | head -n 1 | cut -d: -f1)

    if [ -n "$OFFSET" ]; then
        # Calculate the line number for insertion (before the blank line)
        TARGET_LINE=$((LINE_NUM + OFFSET - 1))
        # Use sed to insert the entry at the target line
        sed -i "''${TARGET_LINE}i\\''${ENTRY}" "$FILE"
    else
        # If no blank line found, we assume it's the end of the file or block
        # and just append at the end
        echo "''${ENTRY}" >> "$FILE"
    fi
  '';

  timeclock-timer =
    let
      # The TUI timer command. Change this to swap out the timer.
      # termdown with no time argument runs as a stopwatch counting forward
      # (press 'q' to quit).
      timerCmd = "termdown";
    in
    pkgs.writeShellApplication {
      name = "timeclock-timer";
      runtimeInputs = with pkgs; [
        hledger
        gum
        fzf
        termdown
        timeclock-add
        hl-accounts
      ];
      text = ''
        # The timer command is kept in a variable so it can be changed easily.
        TIMER_CMD="${timerCmd}"

        # Check if file argument is provided
        if [ $# -eq 0 ]; then
            echo "Usage: $0 <file> [time]"
            echo "  time: optional termdown timespec (e.g. 25m, '1h 5m 30s', 12:00)."
            echo "        If given, runs a countdown instead of a stopwatch."
            exit 1
        fi

        FILE="$1"
        # Optional countdown duration; empty means stopwatch mode.
        TIME_ARG="''${2:-}"

        # Check if file exists
        if [ ! -f "$FILE" ]; then
            echo "File not found: $FILE"
            exit 1
        fi

        # Select the account/project (same selection as clkin/clkout)
        EXISTING_ACCOUNTS=$(hl-accounts "$FILE" 2>/dev/null || true)

        ACCOUNT=""
        if command -v gum >/dev/null 2>&1; then
            if [ -z "$EXISTING_ACCOUNTS" ]; then
                ACCOUNT=$(gum input --placeholder "New file. Enter account name:")
            else
                ACCOUNT=$(echo "$EXISTING_ACCOUNTS" | gum filter --no-strict --placeholder "Select or type account")
            fi
        elif command -v fzf >/dev/null 2>&1; then
            if [ -z "$EXISTING_ACCOUNTS" ]; then
                printf "New file. Enter account name: "
                read -r ACCOUNT
            else
                # --print-query allows typing a new account not in the list. tail -1 grabs either the selection or the typed query.
                ACCOUNT=$(echo "$EXISTING_ACCOUNTS" | fzf --header "Select account (or type new & press Enter)" --print-query | tail -1)
            fi
        else
            echo "Error: neither gum nor fzf found for selection"
            exit 1
        fi

        # Exit if no account selected (e.g. user pressed Esc)
        if [ -z "$ACCOUNT" ]; then
            exit 0
        fi

        # Clock in for the selected project/file
        timeclock-add "$FILE" i "$ACCOUNT"

        # Run the timer, then clock out once it exits (regardless of exit
        # status). With a time argument termdown counts down; without one it
        # runs as a stopwatch counting up.
        if [ -n "$TIME_ARG" ]; then
            "$TIMER_CMD" "$TIME_ARG" || true
        else
            "$TIMER_CMD" || true
        fi

        # Clock out the same project/file
        timeclock-add "$FILE" o "$ACCOUNT"
      '';
    };

  hl-update-prices = pkgs.writeShellScriptBin "hl-update-prices" ''
    PRICEHIST="${pkgs.pricehist}/bin/pricehist" # will install pricehist if not found in systemPackages

    update_currencies() {
      echo "Getting Dollar Price"
      $PRICEHIST fetch ecb EUR/USD -o ledger 2> /dev/null | tail -n 1 >> "$LEDGER_PATH/prices_currencies.hledger"
    }

    update_crypto(){
      TICKER=$1
      NAME=$2
      CRYPTO_PRICEFILE="$LEDGER_PATH/prices_crypto.hledger"
      echo "Getting $NAME Price..."
      $PRICEHIST fetch coinmarketcap "$TICKER" -o ledger 2> /dev/null | tail -n 1 >> "$CRYPTO_PRICEFILE"
    }

    update_stocks() {
      SEARCH="$1"
      TICKER="$2"
      NAME="$3"
      STOCKS_PRICEFILE="$LEDGER_PATH/prices_stocks.hledger"

      echo "Getting $NAME Price..."

      $PRICEHIST fetch yahoo "$SEARCH" -o ledger 2> /dev/null |
        tail -n 1 |
        sed "s/$SEARCH/$TICKER/" >> "$STOCKS_PRICEFILE"
    }

    update_currencies
    update_crypto "BTC/EUR" "Bitcoin"
    update_crypto "TRX/EUR" "Tron"
    update_crypto "XMR/EUR" "Monero"

    update_stocks "PAL.VI" "PAL" "Palfinger"
    update_stocks "APC.DE" "AAPL" "Apple" # Apple on the XETRA Exchange Frankfurt
    update_stocks "LYP6.DE" "\"LYP6\"" "Amundi Core Stoxx Europe 600"
    update_stocks "EUNL.DE" "EUNL" "iShares Core MSCI World"
  '';
}
