export NOTES_DIR=/data/data/com.termux/files/home/storage/documents/notes

export FINANCE_PATH=$NOTES_DIR/Journal/_finance
export LEDGER_FILE=$FINANCE_PATH/2026.hledger
export LEDGER_ALL_FILE=$FINANCE_PATH/all.hledger

export TIME_PATH=$NOTES_DIR/Journal/_time
export TIMEDOT_FILE=$TIME_PATH/2026.timedot
export TIMEDOT_SEM_FILE=$TIME_PATH/uni/2026SS.timedot
export TIMEDOT_WORK_FILE=$TIME_PATH/work/2026.timeclock

bknotes() {
    git add -A
    git commit -m "Backup from Pixel Phone"
    if ping -c 1 -W 1 "10.0.0.151" >/dev/null 2>&1; then
        echo "✅ Server reachable"
        git push
    else
        echo "❌ Server not reachable"
    fi

}

bkinit() {
    rm -rf .git
    git init
    git remote add backup ssh://git@10.0.0.151:2222/bitSheriff/notes.git

    git pull
}

timeclock-add() {
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
        in | i) ACTION="i" ;;
        out | o) ACTION="o" ;;
        *)
            echo "Invalid action: $ACTION_ARG (use in/i or out/o)"
            exit 1
            ;;
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

}

alias hl=hledger
alias hla="hledger -f $LEDGER_ALL_FILE"
# eval "$(mise activate bash)"
alias timedot="hledger -f $HOME/notes/Journal/_time/2026.timedot"
alias td="hledger -f $HOME/notes/Journal/_time/all.journal"
alias tda="~/.local/bin/timedot-add ${TIMEDOT_FILE}"
alias tdauni="~/.local/bin/timedot-add ${TIMEDOT_SEM_FILE}"
alias tdawork="~/.local/bin/timeclock-add ${TIMEDOT_WORK_FILE}"
alias nv=nvim
alias todo=~/.local/bin/todo

alias clkin='FILE=$(cd "${TIME_PATH}" && fd --extension=timeclock --type f | fzf) && [ -n "$FILE" ] && timeclock-add "${TIME_PATH}/${FILE}" i'
alias clkout='FILE=$(cd "${TIME_PATH}" && fd --extension=timeclock --type f | fzf) && [ -n "$FILE" ] && timeclock-add "${TIME_PATH}/${FILE}" o'
