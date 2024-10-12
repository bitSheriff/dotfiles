source "$LIB_PATH/my_lib.sh"
source "$LIB_PATH/distributions.sh"

pacman_install_file() {
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | sudo pacman $PACMAN_FLAGS -S -
}

pacman_install_single() {

    # Check if the package is installed using yay
    if ! pacman -Qi "$1" &>/dev/null; then
        sudo pacman $PACMAN_FLAGS -S "$@"
    fi
}

yay_install_file() {
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | yay $YAY_FLAGS -S -
}

yay_install_single() {
    yay $YAY_FLAGS -S "$@"
}
