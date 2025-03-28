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
# Funtions
# ========================================

setup_battery() {

    print_note "Install powertop for gerneral tuning"
    pacman_install_single "powertop"
    sudo powertop --auto-tune

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

    gum confirm --default=false "Are you using a Framework Laptop?" && (
        yay_install_single fw-ectool-git
    )
}

setup_bluetooth() {

    print_h3 "Bluetooth Setup"

    # install needed packages
    pacman_install_single "bluez"
    pacman_install_single "blueman" # bluetooth manager, GUI

    # activate the service
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
}

setup_nvidia() {

    print_h3 "Nvidia Setup"

    pacman_install_single "linux-headers"
    pacman_install_single "nvidia-dkms"
    pacman_install_single "nvidia-utils"
    pacman_install_single "ib32-nvidia-utils"
    pacman_install_single "egl-wayland"
    pacman_install_single "libva-nvidia-driver"

    # GPU Top
    pacman_install_single "nvtop"
}

setup_fingers() {
    print_h3 "Setup Fingers"

    # Define a map of selections to their corresponding fprintd finger names
    declare -A finger_map=(
        ["R Thumb"]="right-thumb"
        ["R Index"]="right-index-finger"
        ["R Middle"]="right-middle-finger"
        ["R Ring"]="right-ring-finger"
        ["R Little"]="right-little-finger"
        ["L Thumb"]="left-thumb"
        ["L Index"]="left-index-finger"
        ["L Middle"]="left-middle-finger"
        ["L Ring"]="left-ring-finger"
        ["L Little"]="left-little-finger"
    )

    # Display the options for selection using gum
    selection=$(
        gum choose --no-limit \
            "${!finger_map[@]}"
    )

    # Convert the multi-line selection into an array
    IFS=$'\n' read -rd '' -a selected_fingers <<<"$selection"

    # Loop through the selected options and enroll each finger
    for finger in "${selected_fingers[@]}"; do
        fprintd-enroll -f "${finger_map[$finger]}"
    done
}

setup_finger_functions() {

    gum confirm --default=false "Sudo Authentication" && (
        print_h3 "Sudo Authentication"
        sudo grep -qxF 'auth            sufficient      pam_unix.so try_first_pass likeauth nullok' /etc/pam.d/sudo || sudo sed -i '1i auth            sufficient      pam_unix.so try_first_pass likeauth nullok' /etc/pam.d/sudo
        sudo grep -qxF 'auth            sufficient      pam_fprintd.so' /etc/pam.d/sudo || sudo sed -i '1i auth            sufficient      pam_fprintd.so' /etc/pam.d/sudo
    )

    gum confirm --default=false "KDE Authentication" && (
        print_h3 "Sudo Authentication"
        sudo grep -qxF 'auth            sufficient      pam_unix.so try_first_pass likeauth nullok' /etc/pam.d/kde || sudo sed -i '1i auth            sufficient      pam_unix.so try_first_pass likeauth nullok' /etc/pam.d/kde
        sudo grep -qxF 'auth            sufficient      pam_fprintd.so' /etc/pam.d/kde || sudo sed -i '1i auth            sufficient      pam_fprintd.so' /etc/pam.d/kde
    )

    gum confirm --default=false "System Authentication" && (
        print_h3 "System Authentication"
        sudo grep -qxF 'auth            sufficient      pam_fprintd.so' /etc/pam.d/system-auth || sudo sed -i '1i auth            sufficient      pam_fprintd.so' /etc/pam.d/system-auth
    )

}

# ========================================
# Main
# ========================================

print_h2 "Hardware Setup"

selection=$(
    gum choose --no-limit \
        "Battery" \
        "Bluetooth" \
        "Fingerprint" \
        "Logitech Devices" \
        "Nvidia" \
        "Portable Monitors" \
        "WiFi" \
        "ZSA Keyboards"
)

IFS=$'\n' read -rd '' -a array <<<"$selection"

if array_contains "${array[@]}" "Battery"; then setup_battery; fi
if array_contains "${array[@]}" "Bluetooth"; then setup_bluetooth; fi
if array_contains "${array[@]}" "Nvidia"; then setup_nvidia; fi
if array_contains "${array[@]}" "WiFi"; then
    print_h3 "WiFi Setup"
    gum confirm --default=false "Install tool to share WiFi with QR?" && yay_install_single "wifi-qr"
fi

if array_contains "${array[@]}" "Fingerprint"; then
    print_h3 "Fingerprint Reader"
    pacman_install_single "fprintd"
    gum confirm --default=false "Do you want to setup your fingers right now?" && setup_fingers
    gum confirm --default=false "Do you want to setup authentications?" && setup_finger_functions
fi

if array_contains "${array[@]}" "Logitech Devices"; then
    print_h3 "Logitech Devies"
    # install the GUI application to manage logitech devices
    pacman_install_single "solaar"

    # relaod the rules
    sudo udevadm control --reload-rules

    # set flag for user message
    PLEASE_REBOOT=1
fi

if array_contains "${array[@]}" "Portable Monitors"; then
    print_h3 "Portable Monitors"
    # install drivers
    yay_install_single "evdi"
    yay_install_single "displaylink"

    # enable and start the displaylink service
    sudo systemctl enable displaylink
    sudo systemctl start displaylink

    # set flag for user message
    PLEASE_REBOOT=1
fi

if array_contains "${array[@]}" "ZSA Keyboards"; then
    print_h3 "ZSA Keyboards"
    # install keymapping application
    yay_install_single "zsa-keymapp-bin"

    # tool to flash (alternative to chromium-based web-tool)
    gum confirm --default=false "Install QMK? Or do you only flash with chromium-based?" && pacman_install_single "qmk"
fi

gum confirm --default=false "Would you like to update firmware of different devices?" && fwupdmgr update
