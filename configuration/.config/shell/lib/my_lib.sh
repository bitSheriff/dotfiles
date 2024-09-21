# ========================================
# CONSTANTS
# ========================================

# ========================================
#  --- COLORS ---
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Define bold color variables
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_PURPLE='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# Define background color variables
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# ========================================
# Functions
# ========================================

# failsafe source method, only source if file exists
include() {
    [[ -f "$1" ]] && source "$1"
}

# failsafe exec method, only execute if file exists
safe_exec() {
    [[ -f "$1" ]] && bash "$1"
}

confirm() {
    # call with a prompt string or use a default
    read -r -p "$1 - [y/N] " response
    case "$response" in
    [yY][eE][sS] | [yY])
        true
        ;;
    *)
        false
        ;;
    esac
}

print_h1() {
    echo -e "$BOLD_PURPLE\n========== [$1] ==========\n$NC"
}

print_h2() {
    echo -e "$BOLD_BLUE\n---------- [$1] ----------\n$NC"
}

print_h3() {
    echo -e "$BOLD_CYAN\n.......... [$1] ..........\n$NC"
}

print_note() {
    echo ":::: $1 ::::"
}

print_warning() {
    echo -e "$BOLD_YELLOW:::: $1 ::::$NC"
}

print_error() {
    echo -e "$BOLD_RED:::: $1 ::::$NC"
}

toggle_process() {

    PROCESS_NAME="$1"

    # Try to kill the process
    killall "$PROCESS_NAME"

    # Check the exit status of killall
    if [ $? -eq 0 ]; then
        echo "Process $PROCESS_NAME was running and has been killed."
    else
        echo "Process $PROCESS_NAME was not running. Starting it now."
        # Start the process
        $PROCESS_NAME &
    fi

}

# Function to check if a list contains a value
array_contains() {
    local list=("$@")
    local item="${list[-1]}"
    unset list[-1]

    for element in "${list[@]}"; do
        if [[ "$element" == "$item" ]]; then
            return 0
        fi
    done

    return 1
}

# Checks if a provided IP address is present on the local network
ip_present() {
    local ip="$1"
    # Ping the IP address with a timeout of 1 second and count of 1 packet
    if ping -c 1 -W 1 $ip &>/dev/null; then
        exit 0
    else
        exit 1
    fi
}
