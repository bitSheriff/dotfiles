#!/bin/bash

DIR_NAME=$(dirname "$0")
source "$DIR_NAME/../../lib/my_lib.sh"
source "$DIR_NAME/../../lib/logos.sh"
source "$DIR_NAME/../../lib/cache.sh"
source "$DIR_NAME/../../lib/distributions.sh"

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
    pacman_install_single "bluetoothctl"
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

# ========================================
# Main
# ========================================

print_h2 "Hardware Setup"

gum confirm --default=false "Would you like to tweak the Battery?" && setup_battery

gum confirm --default=false "Would you like to setup bluetooth?" && setup_bluetooth

gum confirm --default=false "Would you like to setup wifi?" && (
    print_h3 "WiFi Setup"
    gum confirm --default=false "Install tool to share WiFi with QR?" && yay_install_single "wifi-qr"

)

gum confirm --default=false "Would you like to setup a nvidia gpu?" && setup_nvidia

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
