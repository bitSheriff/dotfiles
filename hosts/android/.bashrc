# ~/.bashrc for the Android Linux Terminal (the Debian VM in Android 15+).
# Linked to ~/.bashrc by ./setup_debian.sh.
#
# The hledger helpers below are duplicated from ../../modules/hledger/scripts.nix
# on purpose. This host has no Nix, and keeping the NixOS module untouched is
# worth more than de-duplicating three shell functions. If you fix a bug in one,
# fix it in the other.
#
# Everything lives above the interactive guard so scripts that source this file
# get the paths too.

export PATH="$HOME/.local/bin:$PATH"

############
## PATHS  ##
############

# Android shares storage into the VM under /mnt/shared. Which subdirectories
# are visible depends on the Android version -- 16 QPR2 exposes nearly all of
# shared storage, older builds only Downloads -- so setup_debian.sh probes for
# the notes directory and records what it found in this file.
# shellcheck disable=SC1091  # written at runtime by setup_debian.sh
[ -f "$HOME/.config/dotfiles-notes-path" ] && . "$HOME/.config/dotfiles-notes-path"
: "${NOTES_DIR:=/mnt/shared/Documents/notes}"
export NOTES_DIR

YEAR="$(date +%Y)"

export FINANCE_PATH="$NOTES_DIR/Journal/_finance"
export LEDGER_FILE="$FINANCE_PATH/$YEAR.hledger"
export LEDGER_ALL_FILE="$FINANCE_PATH/all.hledger"

export TIME_PATH="$NOTES_DIR/Journal/_time"
export TIMEDOT_FILE="$TIME_PATH/$YEAR.timedot"
export TIMEDOT_ALL_FILE="$TIME_PATH/all.journal"
export TIMEDOT_SEMESTER_FILE="$TIME_PATH/uni/2026SS.timedot"
export TIMEDOT_WORK_FILE="$TIME_PATH/work/$YEAR.timeclock"

unset YEAR

export DOTFILES_PATH="${DOTFILES_PATH:-$HOME/code/dotfiles}"

# Forgejo box on the home network.
BACKUP_HOST="10.0.0.151"
BACKUP_PORT="2222"
BACKUP_REMOTE="ssh://git@${BACKUP_HOST}:${BACKUP_PORT}/bitSheriff/notes.git"

##################
## HLEDGER LIBS ##
##################

# Collect accounts from a hledger file AND any sibling files sharing its
# basename (e.g. 2026SS.timeclock next to 2026SS.timedot). timedot and
# timeclock syntaxes cannot be mixed in one hledger invocation, so each file is
# parsed on its own and the results merged.
hl-accounts() {
    if [ $# -eq 0 ]; then
        echo "Usage: hl-accounts <file>" >&2
        return 1
    fi

    local FILE DIR BASENAME STEM ext candidate
    FILE="$1"
    DIR=$(dirname -- "$FILE")
    BASENAME=$(basename -- "$FILE")
    STEM="${BASENAME%.*}"

    {
        hledger -f "$FILE" accounts 2>/dev/null || true

        for ext in journal timedot timeclock hledger ledger; do
            candidate="$DIR/$STEM.$ext"
            [ "$candidate" = "$FILE" ] && continue
            if [ -f "$candidate" ]; then
                hledger -f "$candidate" accounts 2>/dev/null || true
            fi
        done
    } | sort -u
}

# List .timeclock files below $TIME_PATH, relative to it. Debian ships fd as
# fdfind; setup_debian.sh symlinks it, but fall back to find regardless.
_timeclock_files() {
    if command -v fd >/dev/null 2>&1; then
        (cd "$TIME_PATH" && fd --extension=timeclock --type f)
    else
        (cd "$TIME_PATH" && find . -type f -name '*.timeclock' -printf '%P\n')
    fi
}

# Append a clock in/out entry. Missing arguments are prompted for.
# Usage: timeclock-add <file> [in|out|i|o] [account]
timeclock-add() {
    if [ $# -eq 0 ]; then
        echo "Usage: timeclock-add <file> [in|out|i|o] [account]"
        return 1
    fi

    local FILE ACTION_ARG ACCOUNT_ARG ACTION ACCOUNT EXISTING_ACCOUNTS ACTION_SEL DATE TIME ENTRY
    FILE="$1"
    ACTION_ARG="${2:-}"
    ACCOUNT_ARG="${3:-}"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    ACTION=""
    ACCOUNT=""

    if [ -n "$ACTION_ARG" ]; then
        case "$ACTION_ARG" in
        in | i) ACTION="i" ;;
        out | o) ACTION="o" ;;
        *)
            echo "Invalid action: $ACTION_ARG (use in/i or out/o)"
            return 1
            ;;
        esac
    fi

    [ -n "$ACCOUNT_ARG" ] && ACCOUNT="$ACCOUNT_ARG"

    if [ -z "$ACCOUNT" ] || [ -z "$ACTION" ]; then
        if ! command -v fzf >/dev/null 2>&1; then
            echo "Error: Missing arguments and fzf not found for selection"
            return 1
        fi

        EXISTING_ACCOUNTS=$(hl-accounts "$FILE" 2>/dev/null || true)

        if [ -z "$ACCOUNT" ]; then
            if [ -z "$EXISTING_ACCOUNTS" ]; then
                printf "New file. Enter account name: "
                read -r ACCOUNT
            else
                # --print-query allows typing a new account not in the list.
                # tail -1 grabs either the selection or the typed query.
                ACCOUNT=$(echo "$EXISTING_ACCOUNTS" | fzf --header "Select account (or type new & press Enter)" --print-query | tail -1)
            fi
            [ -z "$ACCOUNT" ] && return 0
        fi

        if [ -z "$ACTION" ]; then
            ACTION_SEL=$(printf "in\nout" | fzf --header "Select action")
            [ -z "$ACTION_SEL" ] && return 0
            [ "$ACTION_SEL" = "in" ] && ACTION="i" || ACTION="o"
        fi
    fi

    DATE=$(date +%Y-%m-%d)
    TIME=$(date +%H:%M)

    ENTRY=$(printf "%s %s %s %s" "$ACTION" "$DATE" "$TIME" "$ACCOUNT")
    echo "$ENTRY" >>"$FILE"
}

# Insert a timedot entry under today's date header.
# Usage: timedot-add <file>
timedot-add() {
    if [ $# -eq 0 ]; then
        echo "Usage: timedot-add <file>"
        return 1
    fi

    local FILE ACCOUNT AMOUNT COMMENT ENTRY DATE LINE_NUM OFFSET TARGET_LINE
    FILE="$1"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf not found for account selection"
        return 1
    fi

    # --print-query so a new account can be typed, not just picked. This is
    # what gum filter --no-strict used to allow.
    ACCOUNT=$(hl-accounts "$FILE" | fzf --header "Select account (or type new & press Enter)" --print-query | tail -1)
    [ -z "$ACCOUNT" ] && return 0

    read -r -p "Amount: " AMOUNT
    [ -z "$AMOUNT" ] && return 0

    read -r -p "Comment (optional): " COMMENT

    # 4 spaces indent, account padded to 40, then the amount.
    ENTRY=$(printf "    %-40s    %s" "$ACCOUNT" "$AMOUNT")

    if [ -n "$COMMENT" ]; then
        case "$COMMENT" in
        \;*) ;;
        *) COMMENT="; $COMMENT" ;;
        esac
        ENTRY=$(printf "%s    %s" "$ENTRY" "$COMMENT")
    fi

    DATE=$(date +%Y-%m-%d)
    LINE_NUM=$(grep -n "^$DATE" "$FILE" | cut -d: -f1)

    if [ -z "$LINE_NUM" ]; then
        echo "Date $DATE not found in $FILE"
        return 1
    fi

    # First blank line after the date header is where the block ends.
    OFFSET=$(tail -n "+$LINE_NUM" "$FILE" | grep -n "^$" | head -n 1 | cut -d: -f1)

    if [ -n "$OFFSET" ]; then
        TARGET_LINE=$((LINE_NUM + OFFSET - 1))
        sed -i "${TARGET_LINE}i\\${ENTRY}" "$FILE"
    else
        echo "${ENTRY}" >>"$FILE"
    fi
}

###############
## COMMANDS  ##
###############

clkin() {
    local REL_FILE
    REL_FILE=$(_timeclock_files | fzf) || return 0
    [ -n "$REL_FILE" ] && timeclock-add "$TIME_PATH/$REL_FILE" i
}

clkout() {
    local REL_FILE
    REL_FILE=$(_timeclock_files | fzf) || return 0
    [ -n "$REL_FILE" ] && timeclock-add "$TIME_PATH/$REL_FILE" o
}

tda() { timedot-add "$TIMEDOT_FILE"; }
tdauni() { timedot-add "$TIMEDOT_SEMESTER_FILE"; }
tdawork() { timeclock-add "$TIMEDOT_WORK_FILE" "$@"; }

# Commit the notes and push them if the Forgejo box answers.
# git -C so this is safe to run from anywhere, and a TCP probe on the git port
# rather than ping, because that is what the push actually needs.
bknotes() {
    git -C "$NOTES_DIR" add -A
    git -C "$NOTES_DIR" commit -m "Backup from Pixel Phone" || true

    if timeout 2 bash -c "</dev/tcp/${BACKUP_HOST}/${BACKUP_PORT}" 2>/dev/null; then
        echo "✅ Server reachable"
        git -C "$NOTES_DIR" push
    else
        echo "❌ Server not reachable"
    fi
}

# Re-attach the notes directory to the backup remote from scratch.
# Destructive, so it asks first.
bkinit() {
    local reply
    read -r -p "Delete $NOTES_DIR/.git and pull the history again? [y/N] " reply
    case "$reply" in
    [yY]*) ;;
    *) return 0 ;;
    esac

    rm -rf "${NOTES_DIR:?}/.git"
    git -C "$NOTES_DIR" init
    git -C "$NOTES_DIR" remote add backup "$BACKUP_REMOTE"
    git -C "$NOTES_DIR" pull backup
}

#############
## ALIASES ##
#############

alias hl=hledger
alias hla='hledger -f "$LEDGER_ALL_FILE"'
alias hle='nvim "$LEDGER_FILE"'
alias td='hledger -f "$TIMEDOT_ALL_FILE"'
alias timedot='hledger -f "$TIMEDOT_FILE"'
alias nv=nvim
alias pulldots='(cd "$DOTFILES_PATH" && git pull)'
