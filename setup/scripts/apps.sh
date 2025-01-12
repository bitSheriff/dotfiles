#!/bin/bash

DIR_NAME=$(dirname "$0")
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/my_lib.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/logos.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/cache.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/distributions.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/package_manager.sh"

# ========================================
# CONSTANTS
# ========================================

NAME_iam="[Social/Matrix] iam (TUI)"
NAME_fractal="[Social/Matrix] Fractal (Gtk)"
NAME_element="[Social/Matrix] Fractal (Gtk)"
NAME_signal="[Social] Signal"
NAME_whatsapp="[Social] WhatsApp"
NAME_tuba="[Social/Mastodon] tuba (GTK)"
NAME_tokodon="[Social/Mastodon] Tokodon (QT)"
NAME_toot="[Social/Mastodon] Toot (CLI/TUI)"

NAME_termius="[Dev/Ops] Termius (SSH GUI Client)"
NAME_filezilla="[Dev/Ops] FileZilla"
NAME_devtoys="[Dev] DevToys"
NAME_doxygen="[Dev] Doxygen"
NAME_matlab="[Dev/Math] Matlab"
NAME_maple="[Dev/Math] Maple"
NAME_neovide="[Dev/Editor] Neovide"
NAME_wireshark="[Dev/Network] Wireshark (Qt)"
NAME_syncthing="[Dev/Network] Syncthing"
NAME_tailscale="[Dev/Network] Tailscale"
NAME_xxd="[Dev/Reverse Engineering] xxd (tinyxxd)"
NAME_xxd="[Dev/Reverse Engineering] netcat"

NAME_cozy="[Media/Audio] Cozy Audiobook-Player"
NAME_spotify="[Media/Audio] Spotify"
NAME_pocketcasts="[Media/Audio] Pocket Casts"

NAME_decoder="[Misc] Decoder (QR Scanner)"
NAME_zenbrowser="[Misc] Zen-Browser"
NAME_chromium="[Misc] Chromium"
NAME_missioncenter="[Misc] Mission Center"
NAME_kdeconnect="[Misc] KDE Connect"

NAME_mullvadvpn="[Privacy] Mullvad VPN"
NAME_mullvadbrowser="[Privacy] Mullvad Browser"
NAME_veracrypt="[Privacy] VeraCrypt"
NAME_qbittorrent="[Privacy] QBitTorrent"
NAME_torbowser="[Privacy] TOR Browser"
NAME_ledgerlive="[Privacy] Ledger Live"

NAME_ticktick="[Productivity] TickTick"
NAME_espanso="[Productivity] espanso"
NAME_webapp="[Productivity] WebApp Manager"
NAME_beeper="[Productivity] Beeper"
NAME_typora="[Productivity/Writing] Typora"
NAME_apostrophe="[Productivity/Writing] Apostrophe"

NAME_calibre="[Office/Books] Calibre"
NAME_foliate="[Office/Books] Foliate"
NAME_libreoffice="[Office] LibreOffice Suite"
NAME_onlyoffice="[Office] OnlyOffice"
NAME_qalc="[Office] Qalc"
NAME_zathura="[Office/PDF] Zathura"
NAME_drawio="[Office] Draw.io"
NAME_whisper="[Office/AI] WhisperAI"
NAME_speechNote="[Office/AI] Speech Note"

# ========================================
# Global Variables
# ========================================
# Initialize strings to collect packages
pacman_packages=()
yay_packages=()

# ========================================
# Functions
# ========================================
build_espanso() {

    # build by source becaause AUR packages does not work
    # create the folders if needed
    mkdir -p "$HOME/code/"
    mkdir -p "$HOME/.local/bin"

    (
        cd "$HOME/code/"
        # install the Rust Tools for that
        cargo install --force cargo-make
        # checkout the repository
        git clone https://github.com/espanso/espanso
        cd "$HOME/code/espanso"
        # build the application
        cargo make --profile release --env NO_X11=true build-binary
        # move the binary to the personal binary directory
        sudo mv target/release/espanso "$HOME/.local/bin/"
        # update zsh to get the updated path
        exec zsh
        # give access
        sudo setcap "cap_dac_override+p" "$(which espanso)"
        # register the service and start it
        espanso service register
        espanso start
    )
}

setup_kdeConnect() {

    # install the package
    pacman_install_single "kdeconnect"

    # allow kdeconnect
    sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect
    sudo firewall-cmd --reload
}

setup_zathura() {

    # install the main package
    pacman_install_single "zathura"
    # very versatile engine (epub, pdf, ...)
    pacman_install_single "zathura-pdf-mupdf"

    gum confirm --default=false "Do you read Comic Books?" && pacman_install_single "zathura-cb"
}

# ========================================
# Main
# ========================================

# add all the packages to a list

packages=(
    "$NAME_calibre"
    "$NAME_chromium"
    "$NAME_cozy"
    "$NAME_decoder"
    "$NAME_devtoys"
    "$NAME_doxygen"
    "$NAME_drawio"
    "$NAME_espanso"
    "$NAME_filezilla"
    "$NAME_foliate"
    "$NAME_kdeconnect"
    "$NAME_libreoffice"
    "$NAME_maple"
    "$NAME_matlab"
    "$NAME_missioncenter"
    "$NAME_mullvadbrowser"
    "$NAME_mullvadvpn"
    "$NAME_neovide"
    "$NAME_whisper"
    "$NAME_pocketcasts"
    "$NAME_qbittorrent"
    "$NAME_qalc"
    "$NAME_signal"
    "$NAME_zenbrowser"
    "$NAME_speechNote"
    "$NAME_spotify"
    "$NAME_termius"
    "$NAME_ticktick"
    "$NAME_tokodon"
    "$NAME_tuba"
    "$NAME_fractal"
    "$NAME_iam"
    "$NAME_veracrypt"
    "$NAME_webapp"
    "$NAME_whatsapp"
    "$NAME_zathura"
    "$NAME_torbowser"
    "$NAME_toot"
    "$NAME_wireshark"
    "$NAME_syncthing"
    "$NAME_beeper"
    "$NAME_tailscale"
    "$NAME_xxd"
    "$NAME_netcat"
    "$NAME_apostrophe"
    "$NAME_typora"
    "$NAME_ledgerlive"
    "$NAME_onlyoffice"
)

# sort the packages
IFS=$'\n' sorted_packages=($(sort -V <<<"${packages[*]}"))
unset IFS

# read the wanted apps
selection=$(
    gum choose --no-limit "${sorted_packages[@]}"
)

IFS=$'\n' read -rd '' -a array <<<"$selection"

if array_contains "${array[@]}" "$NAME_calibre"; then pacman_packages+=("calibre"); fi
if array_contains "${array[@]}" "$NAME_chromium"; then pacman_packages+=("chromium"); fi
if array_contains "${array[@]}" "$NAME_decoder"; then yay_packages+=("decoder"); fi
if array_contains "${array[@]}" "$NAME_devtoys"; then yay_packages+=("devtoys-bin"); fi
if array_contains "${array[@]}" "$NAME_doxygen"; then pacman_packages+=("doxygen"); fi
if array_contains "${array[@]}" "$NAME_drawio"; then pacman_packages+=("drawio-desktop"); fi
if array_contains "${array[@]}" "$NAME_filezilla"; then pacman_packages+=("filezilla"); fi
if array_contains "${array[@]}" "$NAME_foliate"; then pacman_packages+=("foliate"); fi
if array_contains "${array[@]}" "$NAME_libreoffice"; then pacman_packages+=("libreoffice-fresh"); fi
if array_contains "${array[@]}" "$NAME_termius"; then yay_packages+=("termius"); fi
if array_contains "${array[@]}" "$NAME_webapp"; then yay_packages+=("webapp-manager"); fi
if array_contains "${array[@]}" "$NAME_qalc"; then pacman_packages+=("qalculate-gtk"); fi
if array_contains "${array[@]}" "$NAME_qbittorrent"; then pacman_packages+=("qbittorrent"); fi
if array_contains "${array[@]}" "$NAME_signal"; then pacman_packages+=("signal-desktop"); fi
if array_contains "${array[@]}" "$NAME_spotify"; then pacman_packages+=("spotify-launcher"); fi
if array_contains "${array[@]}" "$NAME_veracrypt"; then pacman_packages+=("veracrypt"); fi
if array_contains "${array[@]}" "$NAME_ticktick"; then yay_packages+=("ticktick"); fi
if array_contains "${array[@]}" "$NAME_tokodon"; then pacman_packages+=("tokodon"); fi
if array_contains "${array[@]}" "$NAME_tuba"; then pacman_packages+=("tuba"); fi
if array_contains "${array[@]}" "$NAME_neovide"; then pacman_packages+=("neovide"); fi
if array_contains "${array[@]}" "$NAME_iam"; then yay_packages+=("iamb"); fi
if array_contains "${array[@]}" "$NAME_fractal"; then pacman_packages+=("fractal"); fi
if array_contains "${array[@]}" "$NAME_espanso"; then build_espanso; fi
if array_contains "${array[@]}" "$NAME_kdeconnect"; then setup_kdeConnect; fi
if array_contains "${array[@]}" "$NAME_whatsapp"; then yay_packages+=("whatsapp-for-linux"); fi
if array_contains "${array[@]}" "$NAME_matlab"; then bash ./scripts/matlab.sh; fi
if array_contains "${array[@]}" "$NAME_maple"; then bash ./scripts/maple.sh; fi
if array_contains "${array[@]}" "$NAME_cozy"; then yay_packages+=("cozy-audiobooks"); fi
if array_contains "${array[@]}" "$NAME_pocketcasts"; then yay_packages+=("pocket-casts-desktop-bin"); fi
if array_contains "${array[@]}" "$NAME_missioncenter"; then yay_packages+=("mission-center"); fi
if array_contains "${array[@]}" "$NAME_mullvadvpn"; then yay_packages+=("mullvad-vpn"); fi
if array_contains "${array[@]}" "$NAME_mullvadbrowser"; then yay_packages+=("mullvad-browser-bin"); fi
if array_contains "${array[@]}" "$NAME_speechNote"; then yay_packages+=("dsnote"); fi
if array_contains "${array[@]}" "$NAME_whisper"; then yay_packages+=("whisper-git"); fi
if array_contains "${array[@]}" "$NAME_zenbrowser"; then yay_packages+=("zen-browser-bin"); fi
if array_contains "${array[@]}" "$NAME_zathura"; then setup_zathura; fi
if array_contains "${array[@]}" "$NAME_torbowser"; then pacman_packages+=("torbrowser-launcher"); fi
if array_contains "${array[@]}" "$NAME_toot"; then pacman_packages+=("toot"); fi
if array_contains "${array[@]}" "$NAME_wireshark"; then pacman_packages+=("wireshark-qt" "wireshark-cli"); fi
if array_contains "${array[@]}" "$NAME_syncthing"; then pacman_packages+=("syncthing"); fi
if array_contains "${array[@]}" "$NAME_beeper"; then yay_packages+=("beeper-latest-bin"); fi
if array_contains "${array[@]}" "$NAME_xxd"; then pacman_packages+=("tinyxxd"); fi
if array_contains "${array[@]}" "$NAME_netcat"; then pacman_packages+=("gnu-netcat"); fi
if array_contains "${array[@]}" "$NAME_apostrophe"; then pacman_packages+=("Apostrophe"); fi
if array_contains "${array[@]}" "$NAME_typora"; then yay_packages+=("typora"); fi
if array_contains "${array[@]}" "$NAME_ledgerlive"; then yay_packages+=("ledger-live-bin"); fi
if array_contains "${array[@]}" "$NAME_onlyoffice"; then yay_packages+=("onlyoffice-bin"); fi
if array_contains "${array[@]}" "$NAME_tailscale"; then
    sudo pacman -S tailscale
    sudo systemctl enable tailscaled
    sudo systemctl start tailscaled
fi

# synchronize database
sudo pacman -Syy

# Install all the collected oackages
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
