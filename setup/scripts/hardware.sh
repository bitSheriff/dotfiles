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
}

setup_fingers() {
    print_h3 "Setup Fingers"
    selection=$(
        gum choose --no-limit \
            "R Thumb" \
            "R Index" \
            "R Middle" \
            "R Ring" \
            "R Little" \
            "L Thumb" \
            "L Index" \
            "L Middle" \
            "L Ring" \
            "L Little"
    )

    IFS=$'\n' read -rd '' -a array <<<"$selection"

    if array_contains "${array[@]}" "R Thumb"; then fprintd-enroll -f right-thumb; fi
    if array_contains "${array[@]}" "R Index"; then fprintd-enroll -f right-index-finger; fi
    if array_contains "${array[@]}" "R Middle"; then fprintd-enroll -f right-middle-finger; fi
    if array_contains "${array[@]}" "R Ring"; then fprintd-enroll -f right-ring-finger; fi
    if array_contains "${array[@]}" "R Little"; then fprintd-enroll -f right-little-finger; fi

    if array_contains "${array[@]}" "L Thumb"; then fprintd-enroll -f left-thumb; fi
    if array_contains "${array[@]}" "L Index"; then fprintd-enroll -f left-index-finger; fi
    if array_contains "${array[@]}" "L Middle"; then fprintd-enroll -f left-middle-finger; fi
    if array_contains "${array[@]}" "L Ring"; then fprintd-enroll -f left-ring-finger; fi
    if array_contains "${array[@]}" "L Little"; then fprintd-enroll -f left-little-finger; fi
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
