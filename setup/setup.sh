#!/bin/bash

DIR_NAME=$(dirname "$0")

# shellcheck source=/dev/null
source "$DIR_NAME/../lib/my_lib.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../lib/logos.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../lib/cache.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../lib/distributions.sh"

# include the enviroment varaibles (needed for some paths)
include "$DIR_NAME/../configuration/.config/shell/envvars" 2>/dev/null

# ========================================
# FLAGS
# ========================================

PACMAN_FLAGS=" --needed "
YAY_FLAGS=" --needed --answerdiff None --answerclean None --noconfirm"

DEBUG=1

APP_NAME="bitsheriff-setup"
CACHE_HYPRLAND="hyprland"
CACHE_DEV="dev-tools"
CACHE_OFFICE="office-tools"
CACHE_UNI="uni-tools"

# get the arguemnts
ARGV=("$@")
ARG_MODE=("${ARGV[0]}")

# Flags for selective installation
DO_DEV=0
DO_OFFICE=0
DO_UNI=0
DO_HYPR=0
DO_OPTIONALS=0

# Flags for additional installations / setups
DO_ZSH=0
DO_GIT=0
DO_SYMLINKS=0
DO_HARDWARE=0
DO_NIX_PKGS=0

PLEASE_REBOOT=0

# ========================================
# Global Variables
# ========================================
# Initialize strings to collect packages
pacman_packages=()
yay_packages=()

# ========================================
# Functions
# ========================================

print_debug() {

    if [[ "$DEBUG" = 1 ]]; then
        echo "?!?! $1 ?!?!"
    fi
}

do_backup() {
    echo "Backing up installed packages"
    pacman -Qqen >pkglist.txt
    pacman -Qqem >pkglist_aur.txt
}

install_from_backup() {
    echo "Install Pacman Packages"
    sudo pacman $PACMAN_FLAGS -S - <pkglist.txt

    echo "Install AUR Packages"
    yay $YAY_FLAGS -S - <pkglist_aur.txt
}

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

flatpak_install_file() {
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | xargs flatpak install -y
}

nix_install_file() {

    pacman_install_single "nix"

    nix-env -irf "$1"
}

apt_install_file() {
    # remove comments, spaces at the end of the line, and line breaks
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | tr '\n' ' ' | xargs sudo apt install -y
}

create_symlinks() {

    if is_arch; then
        # make sure stow is installed
        pacman_install_single stow
    fi

    if is_debian; then
        # make sure stow is installed
        sudo apt install -y stow
    fi

    # encrypt the secrets
    secret_run

    # find broken symlinks and remove them
    find ~/.config -xtype l -delete
    find ~/Templates -xtype l -delete
    find ~/.local/bin -xtype l -delete

    # stow the packages (no idea why it does not work with $FLAGS)
    stow --adopt -t $HOME -d $DIR_NAME/.. configuration

    # link the templates
    mkdir -p ~/Templates/
    stow --adopt -t ~/Templates -d $DIR_NAME/.. templates

    # link the binaries and scripts which cannot be linked to a specific application (Hyprland, Waybar,...)
    mkdir -p $BIN_PATH
    mkdir -p $LIB_PATH
    stow --adopt -t $BIN_PATH -d $DIR_NAME/.. bin
    stow --adopt -t $LIB_PATH -d $DIR_NAME/.. lib

    # link the wallpaper
    ln -sf $DOTFILES_DIR/wallpapers/ "$HOME/Pictures/"

    # fix some applications (better names) if they are installed
    safe_symlink "/usr/bin/zeditor" "/usr/bin/zed"
    safe_symlink "/usr/bin/pastebin" "/usr/bin/termbin"


    # check if running on Android
    if [[ -z "$TERMUX_VERSION" ]]; then
        # unlink the .termux directory (not needed)
        rm ~/.termux
    fi

}

remove_symlinks() {
    find ~/.config -type l -print0 | xargs -0 rm -v

}

setup_shell() {

    print_h2 "Shell"

    # check if the default shell is already zsh
    if [[ "$SHELL" == "/bin/zsh" ]]; then
        print_note "Shell is already zsh"
    else
        # set zsh as default shell
        chsh -s /bin/zsh
    fi
}

clone_repositories_from_file() {
    target_dir="$1"
    file="$(pwd)/repositories.list"

    # Create the directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        print_note "create code folder: $target_dir"
        mkdir -p "$target_dir"
    else
        print_note "code folder does exist"
    fi

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
    done <$file
}

setup_repositories() {

    print_h1 "Setup Repositories"

    # only execute the file if it exists
    safe_exec ../secrets/clone-repositories.sh
}

install_pkgfiles() {

    # install nix packages if enabled
    if [[ -f "pkgs/$1.nix" && "$DO_NIX_PKGS" = 1 ]]; then
        print_h2 "Installing nix packages from $1"
        nix_install_file "pkgs/$1.nix"
    fi

    # check if the pacman file in the first arguemnt exists
    if [[ -f "pkgs/$1.pkgs" ]]; then
        print_h2 "Installing packages from $1"
        pacman_install_file "pkgs/$1.pkgs"
    fi

    # check if the aur file in the first arguemnt exists
    if [[ -f "pkgs/$1.aur_pkgs" ]]; then
        print_h2 "Installing AUR packages from $1"
        yay_install_file "pkgs/$1.aur_pkgs"
    fi

    # check if the flatpak file in the first arguemnt exists
    if [[ -f "pkgs/$1.flatpak_pkgs" ]]; then
        print_h2 "Installing flatpak packages from $1"
        flatpak_install_file "pkgs/$1.flatpak_pkgs"
    fi
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

install_base() {

    print_h1 "Base"
    print_note "Synchronizing database"
    sudo pacman -Syy
    install_pkgfiles "base"

}

install_hyprland() {

    print_h1 "Hyprland"
    install_pkgfiles "hyprland"

    # setup SDDM
    ensure_sddm_enabled

    # install plugins
    bash $DIR_NAME/scripts/hyprpm.sh

    DO_ZSH=1
}

install_kde_plasma() {

    print_h1 "KDE Plasma"
    install_pkgfiles "kde_plasma"

    ensure_sddm_enabled

    sudo systemctl enable NetworkManager.service

}

install_language_specific() {

    # check if languages have been installed already
    if [ -z ${DONE_LANGUAGE_SPECIF+1} ]; then DONE_LANGUAGE_SPECIF=1; else exit 0; fi

    bash $DIR_NAME/scripts/languages.sh
}

install_dev_tools() {

    print_h1 "Development Tools"
    install_pkgfiles "dev"

    # install packages and languages
    install_language_specific

    gum confirm --default=false "Setup GitHub connection?" && (
        print_h2 "GitHub"
        pacman_install_single "github-cli"

        print_note "Authentication"
        gh auth login

        print_note "Adding ssh-keys to GitHub"

        local title=$(gum input --placeholder "ssh title for GitHub")

        gh ssh-key add ~/.ssh/id_ed25519.pub -t "$title"

        gum confirm --default=false "Install extensions for github-cli?" && (
            gum confirm --default=false "Graph" && gh extension install kawarimidoll/gh-graph
            gum confirm --default=false "Dash (Issue/Pull-Request viewer)" && gh extension install dlvhdr/gh-dash
        )
    )

    gum confirm --default=false "Install LazyDocker?" && yay_packages+=("lazydocker")
    gum confirm --default=false "Install Gnome Connections (VNC/RDP Client)?" && pacman_packages+=("gnome-connections")

    DO_ZSH=1

    # rebuild the bat cache so the theme gets applied
    bat cache --build
}

install_office_tools() {

    print_h1 "Office Tools"
    install_pkgfiles "office"

    gum confirm --default=false "Install OnlyOffice?" && yay_packages+=("onlyoffice-bin")

}

install_uni_tools() {

    print_h1 "University Tools"
    install_pkgfiles "uni"

    install_language_specific
}

install_latex() {

    print_note "LaTeX installation needs a lot of space"
    gum confirm --default=true "Continue anyways?" && install_pkgfiles "latex"
}

install_optionals() {
    print_h1 "Optional Packages"

    bash $DIR_NAME/scripts/apps.sh
}

setup_ssh_keys() {

    # check if SSH keys were already set up
    if [ -z ${DONE_SSH_KEYS+1} ]; then DONE_SSH_KEYS=1; else exit 0; fi

    # Check if SSH keys already exist
    if [ -f ~/.ssh/id_rsa ]; then
        print_note "SSH key already exists:"
        ls -l ~/.ssh/id_rsa*
        print_warning "Skipping SSH key generation."
    else
        # Prompt user for email address
        read -p "Enter your email address for SSH key generation: " email
        if [ -z "$email" ]; then
            print_error "Email address cannot be empty. Exiting."
            exit 1
        fi

        # Generate SSH key pair
        print_note "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -C "$email"
        print_note "SSH key generated successfully:"
        ls -l ~/.ssh/id_rsa*
    fi

    # Start SSH agent (if not running)
    eval "$(ssh-agent -s)"

    # Add SSH private key to SSH agent
    ssh-add ~/.ssh/id_rsa

    # Display SSH public key for easy copying
    print_note "Your SSH public key (copy this to your remote server):"
    cat ~/.ssh/id_rsa.pub

    # Prompt user to wait
    read -n 1 -s -r -p "Press any key to continue and add the SSH key to your server..."
}

setup_yay() {

    # install needed packages to build yay
    pacman_install_single "base-devel"

    # check out the repository
    gti clone https://aur.archlinux.org/yay.git

    # build and install
    sh -c "cd yay && makepkg -si"

    # remove the yay repository
    rm -rf yay

    # make yay faster - do not use compression
    sudo sed -i "s/PKGEXT=.*/PKGEXT='.pkg.tar'/g" /etc/makepkg.conf
    sudo sed -i "s/SRCEXT=.*/SRCEXT='.src.tar'/g" /etc/makepkg.conf
}

change_hostname() {
    local oldHostname=$(hostname)
    local newHostname=$(gum input --value "$oldHostname")

    gum confirm --default=false --affirmative="Yes" --negative="Keep old one" "Would you like to change the hostname to $newHostname" && (
        sudo hostnamectl set-hostname "$newHostname"

        PLEASE_REBOOT=1
    )
}

setup_default_apps() {
    print_h2 "Set Default Applications"

    # avoid complications, so unset the envvars for now
    # else the xdg-setting would fail
    unset BROWSER

    xdg-settings set default-web-browser firefox.desktop

    # set Nemo as default file manager
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

    # set ghostty as defaul terminal
    gsettings set org.cinnamon.desktop.default-applications.terminal exec ghostty
}

safe_symlink() {
    local source="$1"
    local target="$2"

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        echo "Source does not exist: $source. No symlink created."
        return 1
    fi

    # Check if target exists and is not a symlink
    if [[ -e "$target" && ! -L "$target" ]]; then
        echo "Target exists and is not a symlink: $target. Aborting."
        return 2
    fi

    # Remove target if it is a symlink
    if [[ -L "$target" ]]; then
       sudo rm "$target"
    fi

    # Check if target is inside the home directory
    if [[ "$target" == "$HOME"* ]]; then
        # Inside home directory, no sudo needed
        ln -s "$source" "$target"
    else
        # Outside home directory, might need sudo
        sudo ln -s "$source" "$target"
    fi
}

post_install() {
    print_h1 "Post Installation"
    setup_default_apps

    gum confirm --default=false "Would you like to run the secrets?" && secret_run

}

secret_run() {
    bash $DIR_NAME/secret.sh
}

deactivate_gpg_signing() {
    print_h2 "Deactivate GPG"
    print_debug "this is needed if 1Password is not available"

    # deactivate signing
    git config --global commit.gpgSign false

    # ignore the changed file because it should not be commited (signing is important on other devices)
    git update-index --assume-unchanged ../configuration/.gitconfig
}

setup_android() {

    print_h1 "Android Setup"

    # update the database
    pkg updatate
    # upgrade the packages
    pkg upgrade

    # fake the sudo command
    alias sudo=""

    print_h2 "Install packages"
    # android setup with termux
    grep -v '^#' "pkgs/termux.pkgs" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | pkg install -

    # more packages which are not in the repository
    print_note "install SSHS"
    cargo install --git https://github.com/quantumsheep/sshs

    # Deactivate GPG because 1Password is not available on Termux, and else committing is not possible
    deactivate_gpg_signing

    # grant termux access to storage
    termux-setup-storage
    print_note "Termux has no access to the storage (~/storage/)"

    # set ZSH to default shell
    chsh -s "$(which zsh)"

    gum confirm --default=false "Would you like to copy the SSH keys?" && (
        safe_exec ../secrets/ssh-copy.sh
    )

    # create the symlinks
    create_symlinks
}

setup_services() {
    print_h2 "Setup Custom Services"

    # first link, because the services are located in a symlinked directory
    create_symlinks

    bash $DIR_NAME/scripts/custom-services.sh
}

setup_debian() {
    print_h2 "Debian Setup"
    gum confirm --default=false "Would you like to switch to debian unstable packages (sid)" && (
        sudo bash -c 'cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian unstable main contrib non-free
deb-src http://deb.debian.org/debian unstable main contrib non-free
EOF'
        # do a full upgrade
        sudo apt update && sudo apt full-upgrade
    )

    # update the database
    sudo apt update
    # upgrade the packages
    sudo apt upgrade -y

    # install the needed packages
    apt_install_file "$DIR_NAME/pkgs/debian.pkgs"

    # create the symlinks
    create_symlinks
}

# ===============================================
# Flow Start & Arguemnt Handling
# ===============================================

# check if no argument is given (arg[0] is the script name itself)
if [[ ${#ARGV[@]} = 1 ]]; then
    print_logo_config
    print_h1 "Welcome to my setup script"
    echo "the interactive setup will start now"
    echo -e "please stand by ...\n\n"
fi

if [[ "$ARG_MODE" = 'all' ]]; then
    install_base
    install_hyprland
    install_dev_tools
    install_office_tools
    install_uni_tools

    create_symlinks

    exit 0
fi

if [[ "$ARG_MODE" = 'backup' ]]; then
    do_backup
    exit 0
fi

if [[ "$ARG_MODE" = 'update' ]]; then

    print_h1 "Update Setup"

    # pull updates if possible
    git -C "$DOTFILES_DIR" pull

    install_base

    # update the packages from the used bundles
    if check_cache_option "$APP_NAME" "$CACHE_HYPRLAND"; then
        print_note "Hyprland Bundle detected"
        install_hyprland
    fi

    if check_cache_option "$APP_NAME" "$CACHE_DEV"; then
        print_note "Development Bundle detected"
        install_dev_tools
    fi

    if check_cache_option "$APP_NAME" "$CACHE_OFFICE"; then
        print_note "Office Bundle detected"
        install_office_tools
    fi

    if check_cache_option "$APP_NAME" "$CACHE_UNI"; then
        print_note "University Bundle detected"
        install_uni_tools
    fi

    # upadte the symlinks
    create_symlinks
    exit 0
fi

if [[ "$ARG_MODE" = 'link' ]]; then
    create_symlinks
    exit 0
fi

if [[ "$ARG_MODE" = 'unlink' ]]; then
    remove_symlinks
    exit 0
fi

if [[ "$ARG_MODE" = 'debug' ]]; then
    DEBUG=1
    exit 0
fi

if [[ "$ARG_MODE" = 'languages' || "$ARG_MODE" = 'lang' ]]; then
    install_language_specific
    exit 0
fi

if [[ "$ARG_MODE" = 'secrets' || "$ARG_MODE" = 'secret' ]]; then
    secret_run
    exit 0
fi

if [[ "$ARG_MODE" = 'selection' || "$ARG_MODE" = 'apps' ]]; then
    install_optionals
    exit 0
fi

if [[ "$ARG_MODE" = 'services' || "$ARG_MODE" = 'service' ]]; then
    setup_services
    exit 0
fi

if [[ "$ARG_MODE" = 'android' ]]; then
    setup_android
    exit 0
fi

if [[ "$ARG_MODE" = 'repo' || "$ARG_MODE" = 'repos' ]]; then
    setup_repositories
    exit 0
fi

if [[ "$ARG_MODE" = 'help' || "$ARG_MODE" = '--help' || "$ARG_MODE" = '-h' ]]; then
    echo -e "
SYNOPSIS
  setup.sh [OPTIONS] [COMMAND]

DESCRIPTION
  This script is used to build NixOS styled application declaration to Arch.

COMMANDS
  update         Update the existing setup and configurations.
  link           Create symbolic links for the project dependencies.
  unlink         Remove symbolic links for the project dependencies.

OPTIONS
  -h, --help     Display this help message and exit.

EXAMPLES
  ./setup.sh                    # interactive setup
  ./setup.sh update
  ./setup.sh link
  ./setup.sh unlink
  ./setup.sh -h
  ./setup.sh --help
    "

    exit 0
fi

# ========================================
# Preconditions
# ========================================

# Check if it is executed on android
if is_android; then
    setup_android
    exit 0
fi

if is_debian; then
    # setup small debian setup
    setup_debian
    exit 0
fi

if ! is_arch; then
    print_error "Sadly, currently only Arch Linux (and derivates) are supported"
    exit 1
fi

# check if DOTFILES_DIR is set, if not source the env.sh file
if [ -z "$DOTFILES_DIR" ]; then
    source "$DIR_NAME/env.sh"
fi

# ========================================
# Interactions
# ========================================

# select the tools to install
tool_selection=$(gum choose --no-limit "Hyprland" "KDE Plasma" "Development" "University" "LaTeX" "Office" "Local AI" "Audio")

# Converting list from `gum choose` output to an array
IFS=$'\n' read -rd '' -a array <<<"$tool_selection"

gum confirm --default=false "Would you like to setup SSH keys?" && setup_ssh_keys

gum confirm --default=false "Wouldyou like to change the hostname?" && change_hostname

gum confirm --default=false "Would you like to checkout the provided repositories?" && DO_GIT=1

gum confirm --default=false "[INTERACTIVE] Would you like to install the opional packages?" && DO_OPTIONALS=1

gum confirm --default=false "Would you like to link the dotfiles?" && DO_SYMLINKS=1

gum confirm --default=false "Would you like a general hardware setup?" && DO_HARDWARE=1

# ========================================
# Actual Installation & Setup
# ========================================

# base is mandatory
install_base

# check if yay is installed
if ! command -v yay &>/dev/null; then
    print_warning "yay is not installed, it going to be setup now..."
    setup_yay
fi

if array_contains "${array[@]}" "Hyprland" || [ "$DO_HYPR" = 1 ]; then
    write_cache_option "$APP_NAME" "$CACHE_HYPRLAND"
    install_hyprland
fi

if array_contains "${array[@]}" "KDE Plasma" || [ "$DO_HYPR" = 1 ]; then
    install_kde_plasma
fi

if array_contains "${array[@]}" "Development" || [ "$DO_DEV" = 1 ]; then
    write_cache_option "$APP_NAME" "$CACHE_DEV"
    install_dev_tools
fi

if array_contains "${array[@]}" "Office" || [ "$DO_OFFICE" = 1 ]; then
    write_cache_option "$APP_NAME" "$CACHE_OFFICE"
    install_office_tools
fi

if array_contains "${array[@]}" "University" || [ "$DO_UNI" = 1 ]; then
    write_cache_option "$APP_NAME" "$CACHE_UNI"
    install_uni_tools
fi

if array_contains "${array[@]}" "Local AI"; then
    bash $DIR_NAME/scripts/local-ai.sh
fi

if array_contains "${array[@]}" "Audio"; then

    # basic of everything
    pacman_install_single "ffmpeg" "qjackctl"

    # editor to merge, cut and convert (GUI for ffmpeg)
    yay_install_single "losslesscut-bin"
fi


if [[ "$DO_OPTIONALS" = 1 ]]; then
    install_optionals
fi

if [[ "$DO_ZSH" = 1 ]]; then
    setup_shell
fi

if [[ "$DO_GIT" = 1 ]]; then
    setup_repositories
fi

if [[ "$DO_BACKUP" = 1 ]]; then
    do_backup
fi

if [[ "$DO_SYMLINKS" = 1 ]]; then
    create_symlinks
fi

if [[ "$DO_HARDWARE" = 1 ]]; then
    bash $DIR_NAME/scripts/hardware.sh
fi

if [ ${#pacman_packages[@]} -ne 0 ]; then
    pacman_install_single "${pacman_packages[@]}"
    # reset the packages because they have been installed
    pacman_packages=()
fi

# Install all collected yay packages at once
if [ ${#yay_packages[@]} -ne 0 ]; then
    yay_install_single "${yay_packages[@]}"
    # reset the packages because they have been installed
    yay_packages=()
fi

post_install

if [[ "$PLEASE_REBOOT" = 1 ]]; then
    print_warning "Please reboot your computer"
    gum confirm --default=false "Do you want to reboot now?" && sudo reboot

fi
