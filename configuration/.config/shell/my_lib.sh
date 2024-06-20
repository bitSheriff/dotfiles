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

confirm() {
    # call with a prompt string or use a default
    read -r -p "$1 - [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

print_h1(){
    echo -e "$BOLD_PURPLE\n========== [$1] ==========\n$NC"
}

print_h2(){
    echo -e "$BOLD_BLUE\n---------- [$1] ----------\n$NC"
}

print_h3(){
    echo -e "$BOLD_CYAN\n.......... [$1] ..........\n$NC"
}

print_note(){
    echo ":::: $1 ::::"
}

print_warning(){
    echo -e "$BOLD_YELLOW:::: $1 ::::$NC"
}

print_error(){
    echo -e "$BOLD_RED:::: $1 ::::$NC"
}

