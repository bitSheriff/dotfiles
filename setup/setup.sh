#!/bin/bash

DIR_NAME=$(dirname "$0")

source "$DIR_NAME/../configuration/.config/shell/lib/my_lib.sh"
source "$DIR_NAME/../configuration/.config/shell/lib/logos.sh"
source "$DIR_NAME/../configuration/.config/shell/lib/cache.sh"

# ========================================
# FLAGS
# ========================================

PACMAN_FLAGS=" --needed "
YAY_FLAGS=" --needed --answerdiff None --answerclean None --noconfirm"

DEBUG=0

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
DO_LATEX=0
DO_OPTIONALS=0

# Flags for additional installations / setups
DO_ZSH=0
DO_GIT=0
DO_SYMLINKS=0
DO_HARDWARE=0



# ========================================
# Functions
# ========================================

print_debug(){

    if [["$DEBUG" = 1]]; then
        echo "?!?! $1 ?!?!"
    fi;
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

    # Check if the package is installed using yay
    if ! pacman -Qi "$1" &> /dev/null; then
        sudo pacman $PACMAN_FLAGS -S "$1"
    fi
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
    stow -t ~ -d $DIR_NAME/..  configuration

    stow -t ~/Templates -d $DIR_NAME/..  templates
}

remove_symlinks() {
    find ~/.config -type l -print0 | xargs -0 rm -v

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

    print_h2 "Nemo File Manager settings"

    # set Nemo as default file manager
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

    # set kitty as defaul terminal
    gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
}

install_hyprland(){

    print_h1 "Hyprland"
    install_pkgfiles "hyprland"

    # setup SDDM
    ensure_sddm_enabled

    DO_ZSH=1
}

install_dev_tools(){

    print_h1 "Development Tools"
    install_pkgfiles "dev"
    DO_ZSH=1
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


install_optionals(){
    print_h1 "Optional Packages"

    confirm "Install LibreOffice Suite?" && pacman_install_single "libreoffice"

    confirm "Install Termius (SSH Client)?" && yay_install_single "termius"

    confirm "Install Mint WebApp Manager?" && yay_install_single "webapp-manager"

    confirm "Install fake hacker tool 'hollywood'?" && yay_install_single "hollywood"

    confirm "Install KDEConnect?" && pacman_install_single "kdeconnect"

    confirm "Install MEGAsync (Mega Upload client)?" && yay_install_single "megasync"

    confirm "Install WhatsApp?" && yay_install_single "whatsapp-for-linux"

    confirm "Install MATLAB?" && bash ./matlab.sh

    confirm "Install Maple?" && bash ./maple.sh

}

setup_ssh_keys() {
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

setup_bluetooth(){

    print_h3 "Bluetooth Setup"

    # install needed packages
    pacman_install_single "bluez"
    pacman_install_single "bluetoothctl"
    pacman_install_single "blueman"         # bluetooth manager, GUI

    # activate the service
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
}

setup_wifi(){

    print_h3 "WiFi Setup"
}

setup_nvidia(){

    print_h3 "Nvidia Setup"

    pacman_install_single "linux-headers"
    pacman_install_single "nvidia-dkms"
    pacman_install_single "nvidia-utils"
    pacman_install_single "ib32-nvidia-utils"
    pacman_install_single "egl-wayland"
    pacman_install_single "libva-nvidia-driver"

}

setup_yay(){

    # install needed packages to build yay
    pacman_install_single "base-devel"

    # check out the repository
    gti clone https://aur.archlinux.org/yay.git

    # build and install
    sh -c "cd yay && makepkg -si"

    # remove the yay repository
    rm -rf yay
}

setup_hardware(){

    print_h2 "Hardware Setup"

    confirm "Would you like to setup bluetooth?" && setup_bluetooth

    confirm "Would you like to setup wifi?" && setup_wifi

    confirm "Would you like to setup a nvidia gpu?" && setup_nvidia

    confirm "Would you like to update firmware of different devices?" && fwupdmgr update

}

# ========================================
# Flow Start & Arguemnt Handling
# ========================================

if [[ ${#ARGV[@]} = 0 ]]; then
    print_logo_config

    print_h1 "Welcome to my setup script"
    echo "the interactive setup will start now"
    echo -e "please stand by ...\n\n"
fi;

if [[ "$ARG_MODE" = 'all' ]]; then
    install_base
    install_hyprland
    install_dev_tools
    install_office_tools
    install_uni_tools

    create_symlinks

    exit 0
fi;

if [[ "$ARG_MODE" = 'backup' ]]; then
    do_backup
    exit 0
fi;

if [[ "$ARG_MODE" = 'update' ]]; then

    print_h1 "Update Setup"


    # pull updates if possible
    git -C "$DOTFILES_DIR" pull


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
fi;


if [[ "$ARG_MODE" = 'link' ]]; then
    create_symlinks
    exit 0
fi;

if [[ "$ARG_MODE" = 'unlink' ]]; then
    remove_symlinks
    exit 0
fi;

if [[ "$ARG_MODE" = 'debug' ]]; then
    DEBUG=1
    exit 0
fi;

if [[ "$ARG_MODE" = 'help' ||  "$ARG_MODE" = '--help' ||  "$ARG_MODE" = '-h' ]]; then
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
    ";

    exit 0
fi;

# ========================================
# Interactions
# ========================================
confirm "Would you like to setup SSH keys?" && setup_ssh_keys

confirm "Would you like to install Hyprland & Co?" && DO_HYPR=1

confirm "Would you like to install the Development Tools?" && DO_DEV=1

confirm "Would you like to install the Office Tools?" && DO_OFFICE=1

confirm "Would you like to install the University Tools?" && DO_UNI=1

confirm "Would you like to install the LaTeX?" && DO_LATEX=1

confirm "Would you like to checkout the provided repositories?" && DO_GIT=1

confirm "[INTERACTIVE] Would you like to install the opional packages?" && DO_OPTIONALS=1

confirm "Would you like to link the dotfiles?" && DO_SYMLINKS=1

confirm "Would you like a general hardware setup?" && DO_HARDWARE=1


# ========================================
# Actual Installation & Setup
# ========================================

# base is mandatory
install_base

# check if yay is installed
if ! command -v yay &> /dev/null
then
    print_warning "yay is not installed, it going to be setup now..."
    setup_yay
fi


if [[ "$DO_HYPR" = 1 ]]; then
    write_cache_option "$APP_NAME" "$CACHE_HYPRLAND"
    install_hyprland
fi;

if [[ "$DO_DEV" = 1 ]]; then
    write_cache_option "$APP_NAME" "$CACHE_DEV"
    install_dev_tools
fi;

if [[ "$DO_OFFICE" = 1 ]]; then
    write_cache_option "$APP_NAME" "$CACHE_OFFICE"
    install_office_tools
fi;

if [[ "$DO_UNI" = 1 ]]; then
    write_cache_option "$APP_NAME" "$CACHE_UNI"
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
    create_symlinks
fi;

if [[ "$DO_HARDWARE" = 1 ]]; then
    setup_hardware
fi;

