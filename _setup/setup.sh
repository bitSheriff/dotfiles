#!/bin/bash


# ========================================
# COLORS
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
# ========================================
# FLAGS
# ========================================

PACMAN_FLAGS=" --needed "
YAY_FLAGS=" --needed --answerdiff None --answerclean None --noconfirm"

DEBUG=0

# get the arguemnts
ARGV=("$@")
ARG_MODE=("${ARGV[0]}")


# Flags for selective installation
DO_DEV=0
DO_OFFICE=0
DO_UNI=0
DO_HYPR=0
DO_LATEX=0
DO_OPTIONALS=0

# Flags for additional installations / setups
DO_ZSH=0
DO_GIT=0
DO_SYMLINKS=0
DO_NVIM=0
DO_WALLPAPERS=0



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

do_backup(){
    echo "Backing up installed packages"
    pacman -Qqen > pkglist.txt
    pacman -Qqem > pkglist_aur.txt
}

install_from_backup(){
    echo "Install Pacman Packages"
    sudo pacman $PACMAN_FLAGS -S - < pkglist.txt

    echo "Install AUR Packages"
    yay $YAY_FLAGS -S - < pkglist_aur.txt
}

pacman_install_file(){
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | sudo pacman $PACMAN_FLAGS -S -
}

pacman_install_single(){
    sudo pacman $PACMAN_FLAGS -S "$1"
}

yay_install_file(){
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | yay $YAY_FLAGS -S -
}

yay_install_single(){
    yay $YAY_FLAGS -S "$1"
}

flatpak_install(){
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | xargs flatpak install -y 
}

create_symlinks(){

    # make sure stow is installed
    pacman_install_single stow

    # stow the packages (no idea why it does not work with $FLAGS)
    stow  --adopt --restow -t ~ -d ..  ricing
    stow  --adopt --restow -t ~ -d ..  dev
    stow  --adopt --restow -t ~ -d ..  misc

    # Additional ones for comfort
    ln -sf $(pwd)/../wallpapers ~/Pictures/wallpapers

}

remove_symlinks() {
    find ~/.config -type l -print0 | xargs -0 rm -v

}

print_h1(){
    echo -e "\n========== [$1] ==========\n"
}

print_h2(){
    echo -e "\n---------- [$1] ----------\n"
}

print_note(){
    echo ":::: $1 ::::"
}

print_warning(){
    echo -e "$RED" ":::: $1 ::::" "$NC"
}

print_debug(){

    if [["$DEBUG" = 1]]; then
        echo "?!?! $1 ?!?!"
    fi;
}



setup_shell(){

    print_h2 "Shell"

    # check if the default shell is already zsh
    if [[ "$SHELL" == "/bin/zsh" ]]; then
        print_note "Shell is already zsh"
    else
        # set zsh as default shell
        chsh -s /bin/zsh
    fi;
}

setup_repositories(){


    print_h1 "Setup Repositories"

    file="$(pwd)/repositories.list"
    target_dir="$HOME/code"


    # Create the directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        print_note "create code folder: $target_dir"
        mkdir -p "$target_dir"
    else
        print_note "code folder does exist"
    fi;

    # Loop through each line in the file
    while IFS= read -r url; do

        # Skip empty lines
        if [ -z "$url" ]; then
            echo "empty: $url"
            continue
        fi

        # Extract repository name from URL
        repo_name=$(basename -s .git "$url")

        # Check if the repository directory already exists
        if [ -d "$target_dir/$repo_name" ]; then
            echo "Skipping $repo_name, already exists."
            continue
        fi

        echo "Cloning $repo_name"
        
        # Clone the repository
        git clone "$url" "$target_dir/$repo_name"
    done < $file
}

install_pkgfiles(){

    # check if the pacman file in the first arguemnt exists
    if [[ -f "$1.pkgs" ]]; then
        print_h2 "Installing packages from $1"
        pacman_install_file "$1.pkgs"
    fi;

    # check if the aur file in the first arguemnt exists
    if [[ -f "$1.aur_pkgs" ]]; then
        print_h2 "Installing AUR packages from $1"
        yay_install_file "$1.aur_pkgs"
    fi;

    # check if the flatpak file in the first arguemnt exists
    if [[ -f "$1.flatpak_pkgs" ]]; then
        print_h2 "Installing flatpak packages from $1"
        flatpak_install "$1.flatpak_pkgs"
    fi;
}

ensure_sddm_enabled() {
    # Check if sddm is enabled
    if systemctl is-enabled sddm &>/dev/null; then
        print_note "sddm is already enabled."
    else
        print_note "sddm is not enabled. Enabling sddm..."
        sudo systemctl enable sddm
        # Check if the enable command succeeded
        if [ $? -eq 0 ]; then
            print_note "sddm has been enabled successfully."
        else
            print_warning "Failed to enable sddm. Please check the systemctl command and try again."
        fi
    fi
}

install_base(){

    print_h1 "Base"
    install_pkgfiles "base"
}

install_hyprland(){

    print_h1 "Hyprland"
    install_pkgfiles "hyprland"

    # setup SDDM
    ensure_sdd_enabled

    DO_ZSH=1
}

install_dev_tools(){

    print_h1 "Development Tools"
    install_pkgfiles "dev"
    DO_ZSH=1

    # check if the .gitconfig already has a include directive
    if grep -q "\[include\]" ~/.gitconfig; then
        print_note "Gitconfig already has an include directive"
    else
        print_note "Adding include directive to gitconfig"
        echo -e "[include]\n\tpath = ~/.config/git/gitconfig \n\tpath = ~/.config/git/alias" >> ~/.gitconfig
    fi;

}

install_office_tools(){

    print_h1 "Office Tools"
    install_pkgfiles "office"
}

install_uni_tools(){

    print_h1 "University Tools"
    install_pkgfiles "uni"
}

install_latex(){

    ^
    print_note "LaTeX installation needs a lot of space"
    install_pkgfiles "latex"
}

install_benjavim(){
    
    if [ -d "~/.config/nvim/.git" ]; then
        print_warning "nvim already checked out"
    else
        git clone git@github.com:bitSheriff/Benjavim.git ~/.config/nvim
    fi

}

install_wallpapers() {
    if [ -d "~/.config/nvim/.git" ]; then
        print_warning "wallpapers already checked out"
    else
        git clone git@github.com:bitSheriff/wallpapers.git ~/.config/wallpapers
    fi
}

install_optionals(){
    print_h1 "Optional Packages"

    confirm "Install KDE konsole?" && pacman_install_single "konsole"

    confirm "Install Termius (SSH Client)?" && yay_install_single "termius"

    confirm "Install Mint WebApp Manager?" && yay_install_single "webapp-manager"

    confirm "Install fake hacker tool 'hollywood'?" && yay_install_single "hollywood"

    confirm "Install KDEConnect?" && pacman_install_single "kdeconnect"

    confirm "[Private Repo] Install the wallpapers?" && install_wallpapers
}


# ========================================
# Flow Start & Arguemnt Handling
# ========================================

if [[ ${#ARGV[@]} = 0 ]]; then
    print_h1 "Welcome to my setup script"
    echo "the interactive setup will start now"
    echo -e "please stand by ...\n\n"
fi;

if [[ "$ARG_MODE" = 'backup' ]]; then
    do_backup
    exit 0
fi;

if [[ "$ARG_MODE" = 'link' ]]; then
    create_symlinks
    exit 0
fi;

if [[ "$ARG_MODE" = 'unlink' ]]; then
    remove_symlinks
    exit 0
fi;

# ========================================
# Interactions
# ========================================

confirm "Would you like to install Hyprland & Co?" && DO_HYPR=1

confirm "Would you like to install the Development Tools?" && DO_DEV=1

confirm "Would you like to install the Office Tools?" && DO_OFFICE=1

confirm "Would you like to install the University Tools?" && DO_UNI=1

confirm "Would you like to install the LaTex?" && DO_LATEX=1

confirm "Would you like to checkout the provided repositories?" && DO_GIT=1

confirm "[INTERACTIVE] Would you like to install the opional packages?" && DO_OPTIONALS=1

# ========================================
# Actual Installation & Setup
# ========================================

# base is mandatory
install_base

if [[ "$DO_HYPR" = 1 ]]; then
    install_hyprland
fi;

if [[ "$DO_DEV" = 1 ]]; then
    install_dev_tools
fi;

if [[ "$DO_OFFICE" = 1 ]]; then
    install_office_tools
fi;

if [[ "$DO_UNI" = 1 ]]; then
    install_uni_tools
fi;

if [[ "$DO_LATEX" = 1 ]]; then
    install_latex
fi;

if [[ "$DO_OPTIONALS" = 1 ]]; then
    install_optionals
fi;

if [[ "$DO_ZSH" = 1 ]]; then
    setup_shell
fi;

if [[ "$DO_GIT" = 1 ]]; then
    setup_repositories
fi;

if [[ "$DO_BACKUP" = 1 ]]; then
    do_backup
fi;

if [[ "$DO_SYMLINKS" = 1 ]]; then
    print_note "[WIP] nothing will happen"
    # create_symlinks # work in progress
fi;
