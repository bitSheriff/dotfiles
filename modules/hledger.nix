{
  config,
  pkgs,
  username,
  ...
}:

let
  timeclock-add = pkgs.writeShellScriptBin "timeclock-add" ''
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
        if command -v gum >/dev/null 2>&1; then
            # Prompt for account if not provided
            if [ -z "$ACCOUNT" ]; then
                ACCOUNT=$(hledger -f "$FILE" accounts | gum filter --placeholder "Select account")
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
                ACCOUNT=$(hledger -f "$FILE" accounts | fzf --header "Select account")
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

  timedot-add = pkgs.writeShellScriptBin "timedot-add" ''
    # Check if file argument is provided
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <file>"
        exit 1
    fi

    FILE="$1"

    # Check if file exists
    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    # Get inputs using gum if available, otherwise fallback to fzf/read
    if command -v gum >/dev/null 2>&1; then
        # Select account using hledger and gum
        ACCOUNT=$(hledger -f "$FILE" accounts | gum filter --placeholder "Select account")

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
            ACCOUNT=$(hledger -f "$FILE" accounts | fzf --header "Select account")
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

    # Get current date in YYYY-MM-DD format
    DATE=$(date +%Y-%m-%d)

    # Find the line number of the date header
    LINE_NUM=$(grep -n "^$DATE" "$FILE" | cut -d: -f1)

    if [ -z "$LINE_NUM" ]; then
        echo "Date $DATE not found in $FILE"
        exit 1
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
    update_stocks "AAPL" "AAPL" "Apple"
    update_stocks "LYP6.DE" "\"LYP6\"" "Amundi Core Stoxx Europe 600"
    update_stocks "EUNL.DE" "EUNL" "iShares Core MSCI World"
  '';

in
{
  environment.systemPackages = with pkgs; [
    hledger
    hledger-ui
    hledger-web
    hledger-iadd
    pricehist # fetch stock and crypto prices
    # own scripts
    timeclock-add
    timedot-add
    hl-update-prices
  ];

  # Use interactiveShellInit for all variables to ensure they are available in the shell
  # and properly expanded with $HOME and $(date).
  programs.zsh.interactiveShellInit = ''
    export LEDGER_PATH="$HOME/notes/Journal/_finance"
    export LEDGER_FILE="$LEDGER_PATH/2026.hledger"
    export LEDGER_ALL_FILE="$LEDGER_PATH/all.hledger"
    export LEDGER_TEMPLATE_FILE="$LEDGER_PATH/templates.hledger"

    export TIMEDOT_PATH="$HOME/notes/Journal/_time"
    export TIMEDOT_ALL_FILE="$TIMEDOT_PATH/all.journal"
    export TIMEDOT_SEMESTER_FILE="$TIMEDOT_PATH/uni/2026SS.timedot"

    export LEDGER_ACCOUNTS_FILE="$LEDGER_PATH/$(date +%Y)_accounts.hledger"
    export TIMEDOT_FILE="$TIMEDOT_PATH/$(date +%Y).timedot"
    export TIMEDOT_WORK_FILE="$TIMEDOT_PATH/work/$(date +%Y).timeclock"
  '';

  programs.zsh.shellAliases = {
    hl = "hledger";
    hla = "hledger -f \${LEDGER_ALL_FILE}";
    hlae = "(cd $LEDGER_PATH && nvim $(find . -type f | fzf))";

    hla-gain = "hledger -f \${LEDGER_ALL_FILE} bs --gain --value=now,EUR";
    hl-budget = "hledger bal expenses --budget";
    hl-temp = "hledger-templates";
    hle = "nv \${LEDGER_FILE}";

    td = "hledger -f \${TIMEDOT_ALL_FILE}";
    tde = "(cd $TIMEDOT_PATH && nvim $(find . -type f | fzf))";
    tda = "timedot-add \${TIMEDOT_FILE}";
    tdauni = "timedot-add \${TIMEDOT_SEMESTER_FILE}";
    tdawork = "timeclock-add \${TIMEDOT_WORK_FILE}";
    clockin = "timeclock-add \${TIMEDOT_WORK_FILE} i";
    clockout = "timeclock-add \${TIMEDOT_WORK_FILE} o";
  };

  home-manager.users.${username} = {
    xdg.configFile."hledger/hledger.conf".text = ''
      [check] --strict
      [balancesheet] --layout=bare
    '';
  };
}
