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
# Global Variables
# ========================================
# Initialize strings to collect packages
pacman_packages=()
yay_packages=()

# ========================================
# Functions
# ========================================

# ========================================
# Main
# ========================================
#
# read the wanted languages
selection=$(
    gum choose --no-limit \
        "Calibre" \
        "Chromium" \
        "Cozy Audiobook-Player" \
        "Decoder (QR)" \
        "DevToys" \
        "Doxygen" \
        "Draw.io" \
        "espanso" \
        "FileZilla" \
        "Foliate" \
        "KDEConnect" \
        "LibreOffice Suite" \
        "iamb (TUI Matrix Client)" \
        "MATLAB" \
        "Maple" \
        "Mission Center" \
        "Mullvad Browser" \
        "Mullvad VPN" \
        "Neovide" \
        "OpenAI Whisper" \
        "Pocket Casts" \
        "QBitTorrent" \
        "Qalc" \
        "Signal" \
        "SpeechNote" \
        "Spotify" \
        "Termius ssh-client" \
        "TickTick" \
        "Tokodon" \
        "Tuba (Mastodon)" \
        "VeraCrypt" \
        "WebApp Manager" \
        "WhatsApp" \
        "Zathura" \
        "Zen-Browser"
)

IFS=$'\n' read -rd '' -a array <<<"$selection"

if array_contains "${array[@]}" "Calibre"; then pacman_packages+=("calibre"); fi
if array_contains "${array[@]}" "Chromium"; then pacman_packages+=("chromium"); fi
if array_contains "${array[@]}" "Decoder (QR)"; then yay_packages+=("decoder"); fi
if array_contains "${array[@]}" "DevToys"; then yay_packages+=("devtoys-bin"); fi
if array_contains "${array[@]}" "Doxygen"; then pacman_packages+=("doxygen"); fi
if array_contains "${array[@]}" "Draw.io"; then pacman_packages+=("drawio-desktop"); fi
if array_contains "${array[@]}" "FileZilla"; then pacman_packages+=("filezilla"); fi
if array_contains "${array[@]}" "Foliate"; then pacman_packages+=("foliate"); fi
if array_contains "${array[@]}" "LibreOffice Suite"; then pacman_packages+=("libreoffice-fresh"); fi
if array_contains "${array[@]}" "Termius ssh-client"; then yay_packages+=("termius"); fi
if array_contains "${array[@]}" "WebApp Manager"; then yay_packages+=("webapp-manager"); fi
if array_contains "${array[@]}" "Qalc"; then pacman_packages+=("qalculate-gtk"); fi
if array_contains "${array[@]}" "QBitTorrent"; then pacman_packages+=("qbittorrent"); fi
if array_contains "${array[@]}" "Signal"; then pacman_packages+=("signal-desktop"); fi
if array_contains "${array[@]}" "Spotify"; then pacman_packages+=("spotify-launcher"); fi
if array_contains "${array[@]}" "VeraCrypt"; then pacman_packages+=("veracrypt"); fi
if array_contains "${array[@]}" "TickTick"; then yay_packages+=("ticktick"); fi
if array_contains "${array[@]}" "Tokodon"; then pacman_packages+=("tokodon"); fi
if array_contains "${array[@]}" "Tuba (Mastodon)"; then pacman_packages+=("tuba"); fi
if array_contains "${array[@]}" "Neovide"; then pacman_packages+=("neovide"); fi
if array_contains "${array[@]}" "iamb (TUI Matrix Client)"; then yay_packages+=("iamb"); fi
if array_contains "${array[@]}" "espanso"; then
    # build by source becaause AUR packages does not work
    (
        # create the folders if needed
        mkdir -p "$HOME/code/"
        mkdir -p "$HOME/bin"

        # install the Rust Tools for that
        cargo install --force cargo-make
        # checkout the repository
        git clone https://github.com/espanso/espanso
        # build the application
        cargo make --profile release --env NO_X11=true build-binary
        # move the binary to the personal binary directory
        sudo mv target/release/espanso "$HOME/bin/"
        # update zsh to get the updated path
        exec zsh
        # give access
        sudo setcap "cap_dac_override+p" "$(which espanso)"
        # register the service and start it
        espanso service register
        espanso start

    )
fi

if array_contains "${array[@]}" "KDEConnect"; then

    # install the package
    pacman_install_single "kdeconnect"

    # allow kdeconnect
    sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect
    sudo firewall-cmd --reload
fi

if array_contains "${array[@]}" "WhatsApp"; then yay_packages+=("whatsapp-for-linux"); fi
if array_contains "${array[@]}" "MATLAB"; then bash ./scripts/matlab.sh; fi
if array_contains "${array[@]}" "Maple"; then bash ./scripts/maple.sh; fi
if array_contains "${array[@]}" "Cozy Audiobook-Player"; then yay_packages+=("cozy-audiobooks"); fi
if array_contains "${array[@]}" "Pocket Casts"; then yay_packages+=("pocket-casts-desktop-bin"); fi
if array_contains "${array[@]}" "Mission Center"; then yay_packages+=("mission-center"); fi
if array_contains "${array[@]}" "Mullvad VPN"; then yay_packages+=("mullvad-vpn"); fi
if array_contains "${array[@]}" "Mullvad Browser"; then yay_packages+=("mullvad-browser"); fi
if array_contains "${array[@]}" "SpeechNote"; then yay_packages+=("dsnote"); fi
if array_contains "${array[@]}" "OpenAI Whisper"; then yay_packages+=("whisper-git"); fi
if array_contains "${array[@]}" "Zen-Browser"; then yay_packages+=("zen-browser-bin"); fi

if array_contains "${array[@]}" "Zathura"; then

    # install the main package
    pacman_install_single "zathura"
    # very versatile engine (epub, pdf, ...)
    pacman_install_single "zathura-pdf-mupdf"

    gum confirm --default=false "Do you read Comic Books?" && pacman_install_single "zathura-cb"
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
