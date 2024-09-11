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
        sudo pacman $PACMAN_FLAGS -S "$1"
    fi
}

yay_install_file() {
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | yay $YAY_FLAGS -S -
}

yay_install_single() {
    yay $YAY_FLAGS -S "$1"
}

flatpak_install_file() {
    # remove comments and spaces at the end of the line
    grep -v '^#' "$1" | grep -o '^[^#]*' | sed 's/[[:space:]]*$//' | xargs flatpak install -y
}

nix_install_file() {

    pacman_install_single "nix"

    nix-env -irf "$1"
}

create_symlinks() {

    # make sure stow is installed
    pacman_install_single stow

    # find broken symlinks and remove them
    find ~/.config -xtype l -delete
    find ~/Templates -xtype l -delete
    find ~/bin -xtype l -delete

    # stow the packages (no idea why it does not work with $FLAGS)
    stow --adopt -t ~ -d $DIR_NAME/.. configuration

    # link the templates
    stow --adopt -t ~/Templates -d $DIR_NAME/.. templates

    # link the binaries and scripts which cannot be linked to a specific application (Hyprland, Waybar,...)
    stow --adopt -t ~/bin -d $DIR_NAME/.. bin

    # link the secrets if the file is found
    if [ -d "$DOTFILES_DIR/secrets" ]; then
        bash $DOTFILES_DIR/secrets/link.sh
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

setup_repositories() {

    print_h1 "Setup Repositories"

    file="$(pwd)/repositories.list"
    target_dir="$HOME/code"

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

install_pkgfiles() {

    # install nix packages if enabled
    if [[ -f "$1.nix" && "$DO_NIX_PKGS" = 1 ]]; then
        print_h2 "Installing nix packages from $1"
        nix_install_file "$1.nix"
    fi

    # check if the pacman file in the first arguemnt exists
    if [[ -f "$1.pkgs" ]]; then
        print_h2 "Installing packages from $1"
        pacman_install_file "$1.pkgs"
    fi

    # check if the aur file in the first arguemnt exists
    if [[ -f "$1.aur_pkgs" ]]; then
        print_h2 "Installing AUR packages from $1"
        yay_install_file "$1.aur_pkgs"
    fi

    # check if the flatpak file in the first arguemnt exists
    if [[ -f "$1.flatpak_pkgs" ]]; then
        print_h2 "Installing flatpak packages from $1"
        flatpak_install_file "$1.flatpak_pkgs"
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
    install_pkgfiles "base"

}

install_hyprland() {

    print_h1 "Hyprland"
    install_pkgfiles "hyprland"

    # setup SDDM
    ensure_sddm_enabled

    DO_ZSH=1
}

install_language_specific() {

    # check if languages have been installed already
    if [ -z ${DONE_LANGUAGE_SPECIF+1} ]; then DONE_LANGUAGE_SPECIF=1; else exit 0; fi

    print_h2 "Languages and langauge-specific Tooling"

    # read the wanted languages
    local selection=$(
        gum choose --no-limit \
            "Bash" \
            "C" \
            "LaTeX" \
            "Markdown" \
            "Python" \
            "Rust" \
            "Typst"
    )

    # Converting list from `gum choose` output to an array
    IFS=$'\n' read -rd '' -a array <<<"$selection"

    if array_contains "${array[@]}" "Bash"; then
        print_note "Language Bash"
        pacman_install_single "bash"
        pacman_install_single "bash-completion"
        pacman_install_single "bash-language-server"
    fi

    if array_contains "${array[@]}" "C"; then
        print_note "Language C"
        pacman_install_single "clang"
        pacman_install_single "cunit" # test-framework for c

        # CLI debugging Tools
        pacman_install_single "lldb"
        yay_install_single "codelldb"
    fi

    if array_contains "${array[@]}" "Markdown"; then
        print_note "Language Markdown"
        pacman_install_single "neovim"
        pacman_install_single "ghostwriter"
        # CLI Markdown Rederer
        pacman_install_single "glow"

        gum confirm --default=false "Install Hugo Server?" && pacman_install_single "hugo"
        gum confirm --default=false "Install Obsidian?" && yay_install_single "obsidian"
    fi

    if array_contains "${array[@]}" "Rust"; then
        print_note "Language Rust"

        # Language and LSP
        pacman_install_single "rustup"
        pacman_install_single "rust-analyzer"

        # CLI debugging Tools
        pacman_install_single "lldb"
        yay_install_single "codelldb"

        # optional IDE
        gum confirm --default=false "Install RustRover IDE?" && yay_install_single "rustrover"

        # set rust version
        rustup default stable

        # add the formatter component
        rustup component add rustfmt
        rustup component add clippy
    fi

    if array_contains "${array[@]}" "Python"; then
        print_note "Language Python"
        pacman_install_single "python"

        gum confirm --default=false "Install Qt Framework?" && (
            pacman_install_single "python-pyqt5"
            pacman_install_single "python-pyqt6"
        )

        gum confirm --default=false "Install PyCharm Community?" && pacman_install_single "pycharm-community-edition"

        gum confirm --default=false "Install Jupyter?" && pacman_install_single "jupyterlab"
    fi

    if array_contains "${array[@]}" "LaTeX"; then
        print_note "Language LaTeX"
        install_latex
    fi

    if array_contains "${array[@]}" "Typst"; then
        print_note "Language Typst"
        pacman_install_single "typst"
        pacman_install_single "typst-lsp"
    fi
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

    gum confirm --default=false "Install LazyDocker?" && yay_install_single "lazydocker"
    gum confirm --default=false "Install Gnome Connections (VNC/RDP Client)?" && pacman_install_single "gnome-connections"

    DO_ZSH=1
}

install_office_tools() {

    print_h1 "Office Tools"
    install_pkgfiles "office"

    gum confirm --default=false "Install OnlyOffice?" && yay_install_single "onlyoffice-bin"

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

    # read the wanted languages
    local selection=$(
        gum choose --no-limit \
            "Calibre" \
            "Chromium" \
            "Cozy Audiobook-Player" \
            "Decoder (QR)" \
            "DevToys" \
            "Doxygen" \
            "Draw.io" \
            "FileZilla" \
            "Foliate" \
            "KDEConnect" \
            "LibreOffice Suite" \
            "MATLAB" \
            "Maple" \
            "Mullvad VPN" \
            "OpenAI Whisper" \
            "Pocket Casts" \
            "QBitTorrent" \
            "Qalc" \
            "Signal" \
            "SpeechNote" \
            "Spotify" \
            "Termius ssh-client" \
            "TickTick" \
            "VeraCrypt" \
            "WebApp Manager" \
            "WhatsApp" \
            "Zathura" \
            "Zen-Browser"
    )

    IFS=$'\n' read -rd '' -a array <<<"$selection"

    if array_contains "${array[@]}" "Calibre"; then { pacman_install_single "calibre"; }; fi
    if array_contains "${array[@]}" "Chromium"; then { pacman_install_single "chromium"; }; fi
    if array_contains "${array[@]}" "Decoder (QR)"; then { yay_install_single "decoder"; }; fi
    if array_contains "${array[@]}" "DevToys"; then { yay_install_single "devtoys-bin"; }; fi
    if array_contains "${array[@]}" "Doxygen"; then { pacman_install_single "doxygen"; }; fi
    if array_contains "${array[@]}" "Draw.io"; then { pacman_install_single "drawio-desktop"; }; fi
    if array_contains "${array[@]}" "FileZilla"; then { pacman_install_single "filezilla"; }; fi
    if array_contains "${array[@]}" "Foliate"; then { pacman_install_single "foliate"; }; fi
    if array_contains "${array[@]}" "LibreOffice Suite"; then { pacman_install_single "libreoffice-fresh"; }; fi
    if array_contains "${array[@]}" "Termius ssh-client"; then { yay_install_single "termius"; }; fi
    if array_contains "${array[@]}" "WebApp Manager"; then { yay_install_single "webapp-manager"; }; fi
    if array_contains "${array[@]}" "Qalc"; then { pacman_install_single "qalculate-gtk"; }; fi
    if array_contains "${array[@]}" "QBitTorrent"; then { pacman_install_single "qbittorrent"; }; fi
    if array_contains "${array[@]}" "Signal"; then { pacman_install_single "signal-desktop"; }; fi
    if array_contains "${array[@]}" "Spotify"; then { pacman_install_single "spotify-launcher"; }; fi
    if array_contains "${array[@]}" "VeraCrypt"; then { pacman_install_single "veracrypt"; }; fi
    if array_contains "${array[@]}" "TickTick"; then { yay_install_single "ticktick"; }; fi

    if array_contains "${array[@]}" "KDEConnect"; then

        # install the package
        pacman_install_single "kdeconnect"

        # allow kdeconnect
        sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect
        sudo firewall-cmd --reload
    fi

    if array_contains "${array[@]}" "WhatsApp"; then { yay_install_single "whatsapp-for-linux"; }; fi
    if array_contains "${array[@]}" "MATLAB"; then { bash ./matlab.sh; }; fi
    if array_contains "${array[@]}" "Maple"; then { bash ./maple.sh; }; fi
    if array_contains "${array[@]}" "Cozy Audiobook-Player"; then { yay_install_single "cozy-audiobooks"; }; fi
    if array_contains "${array[@]}" "Pocket Casts"; then { yay_install_single "pocket-casts-desktop-bin"; }; fi
    if array_contains "${array[@]}" "Mullvad VPN"; then { yay_install_single "mullvad-vpn"; }; fi
    if array_contains "${array[@]}" "SpeechNote"; then { yay_install_single "dsnote"; }; fi
    if array_contains "${array[@]}" "OpenAI Whisper"; then { yay_install_single "whisper-git"; }; fi
    if array_contains "${array[@]}" "Zen-Browser"; then { yay_install_single "zen-browser-bin"; }; fi

    if array_contains "${array[@]}" "Zathura"; then

        # install the main package
        pacman_install_single "zathura"
        # very versatile engine (epub, pdf, ...)
        pacman_install_single "zathura-pdf-mupdf"

        gum confirm --default=false "Do you read Comic Books?" && pacman_install_single "zathura-cb"
    fi
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

setup_hardware() {

    print_h2 "Hardware Setup"

    gum confirm --default=false "Would you like to tweak the Battery?" && (
        print_note "TLP is only recommended vor Lenovo Laptops"

        # read the wanted package, only one is allowed
        local selection=$(
            gum choose \
                "TLP" \
                "Power-Profiles-Daemon"
        )

        # Converting list from `gum choose` output to an array
        IFS=$'\n' read -rd '' -a array <<<"$selection"

        if array_contains "${array[@]}" "TLP"; then
            pacman_install_single "tlp"
            # start the service for the next boot
            sudo systemctl enable tlp.service
            # start now to use it withour rebooting
            sudo tlp start
        fi

        if array_contains "${array[@]}" "Power-Profiles-Daemon"; then
            pacman_install_single "power-profiles-daemon"

            # start the service for the next boot
            sudo systemctl start power-profiles-daemon.service
        fi

    )

    gum confirm --default=false "Would you like to setup bluetooth?" && (
        print_h3 "Bluetooth Setup"

        # install needed packages
        pacman_install_single "bluez"
        pacman_install_single "bluetoothctl"
        pacman_install_single "blueman" # bluetooth manager, GUI

        # activate the service
        sudo systemctl enable bluetooth
        sudo systemctl start bluetooth

    )

    gum confirm --default=false "Would you like to setup wifi?" && (
        print_h3 "WiFi Setup"
        gum confirm --default=false "Install tool to share WiFi with QR?" && yay_install_single "wifi-qr"

    )

    gum confirm --default=false "Would you like to setup a nvidia gpu?" && (
        print_h3 "Nvidia Setup"

        pacman_install_single "linux-headers"
        pacman_install_single "nvidia-dkms"
        pacman_install_single "nvidia-utils"
        pacman_install_single "ib32-nvidia-utils"
        pacman_install_single "egl-wayland"
        pacman_install_single "libva-nvidia-driver"

    )

    gum confirm --default=false "Would you like to update firmware of different devices?" && fwupdmgr update

    gum confirm --default=false "Would you like to use Logitech devices?" && (
        # install the GUI application to manage logitech devices
        pacman_install_single "solaar"

        # relaod the rules
        sudo udevadm control --reload-rules

        # set flag for user message
        PLEASE_REBOOT=1
    )

    gum confirm --default=false "Would you like to setup a Portable Monitor?" && (

        # install drivers
        yay_install_single "evdi"
        yay_install_single "displaylink"

        # enable and start the displaylink service
        sudo systemctl enable displaylink
        sudo systemctl start displaylink

        # set flag for user message
        PLEASE_REBOOT=1
    )

    gum confirm --default=false "Would you like to setup a zsa keyboard?" && (
        # install keymapping application
        yay_install_single "zsa-keymapp-bin"

        # tool to flash (alternative to chromium-based web-tool)
        gum confirm --default=false "Install QMK? Or do you only flash with chromium-based?" && pacman_install_single "qmk"
    )
}

change_hostname() {
    local oldHostname=$(hostname)
    local newHostname=$(gum input --value "$oldHostname")

    gum confirm --default=false "Would you like to change the hostname to $newHostname" && (
        sudo hostnamectl set-hostname "$newHostname"

        PLEASE_REBOOT=1
    )
}

setup_default_apps() {
    print_h2 "Set Defaul Applications"

    # avoid complications, so unset the envvars for now
    # else the xdg-setting would fail
    unset BROWSER

    xdg-settings set default-web-browser firefox.desktop

    # set Nemo as default file manager
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

    # set kitty as defaul terminal
    gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
}

post_install() {
    print_h1 "Post Installation"
    setup_default_apps

    gum confirm --default=false "Would you like to run the secrets?" && secret_run

}

generic_encrypt() {
    input=$1
    output=$2

    print_debug "encrypting $input > $output"

    # check if the enviroment varaible with the passphrase is set
    if [ -z "$GPG_DOTFILES_PASSWORD" ]; then
        gpg --symmetric --batch --yes --armor -o "$output" "$input"
    else
        gpg --symmetric --passphrase "$GPG_DOTFILES_PASSWORD" --batch --yes --armor -o "$output" "$input"
    fi

}

secret_encrypt() {
    print_h1 "Secret: Encrypt"

    generic_encrypt "secret.sh" "secret.sh.gpg"
    generic_encrypt "$HOME/.ssh/hosts" "ssh_hosts.gpg"
}

generic_decrypt() {
    input=$1
    output=$2

    print_debug "decrypting $input > $output"
    # check if the enviroment varaible with the passphrase is set
    if [ -z "$GPG_DOTFILES_PASSWORD" ]; then
        gpg --decrypt --batch --yes -o "$output" "$input"
    else
        gpg --decrypt --passphrase "$GPG_DOTFILES_PASSWORD" --batch --yes -o "$output" "$input"
    fi

}

secret_decrypt() {
    print_h1 "Secret: Decrypt"

    generic_decrypt "secret.sh.gpg" "secret.sh"
    generic_decrypt "ssh_hosts.gpg" "$HOME/.ssh/hosts"
}

secret_run() {
    # Überprüfen, ob die Datei secret.sh existiert
    if [ -f "secret.sh" ]; then
        print_debug "Secret already encrypted"
    else
        print_debug "Decrypt the Secret file"
        secret_dectypt
    fi

    # check if the secret file was correct decrypted -> the main function exists
    if grep -q "^secret_main()" secret.sh; then

        # source the file and execute the function
        source secret.sh
        secret_main

    else
        print_debug "Something went wrong with decryption"
        exit 1
    fi
}

# ==confirm======================================
# Fl       ow Start & Arguemnt Handling
# ==confirm======================================

if [[ ${#ARGV[@]} = 0 ]]; then
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

if [[ "$ARG_MODE" = 'languages' ]]; then
    install_language_specific
    exit 0
fi

if [[ "$ARG_MODE" = 'encrypt' ]]; then
    secret_encrypt
    exit 0
fi

if [[ "$ARG_MODE" = 'decrypt' ]]; then
    secret_decrypt
    exit 0
fi

if [[ "$ARG_MODE" = 'selection' ]]; then
    install_optionals
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
# Interactions
# ========================================

# select the tools to install
tool_selection=$(gum choose --no-limit "Hyprland" "Development" "University" "LaTeX" "Office")

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
    setup_hardware
fi

post_install

if [[ "$PLEASE_REBOOT" = 1 ]]; then
    print_warning "Please reboot your computer"
    gum confirm --default=false "Do you want to reboot now?" && sudo reboot

fi
