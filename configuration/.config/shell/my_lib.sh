# ========================================
# CONSTANTS
# ========================================


# ========================================
#  --- COLORS ---
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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
    echo -e "$PURPLE\n========== [$1] ==========\n$NC"
}

print_h2(){
    echo -e "\n---------- [$1] ----------\n"
}

print_h3(){
    echo -e "\n.......... [$1] ..........\n"
}

print_note(){
    echo ":::: $1 ::::"
}

print_warning(){
    echo -e "$YELLOW:::: $1 ::::$NC"
}

print_error(){
    echo -e "$RED:::: $1 ::::$NC"
}

