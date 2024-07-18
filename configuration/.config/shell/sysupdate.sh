#!/bin/bash

source ~/.config/shell/lib/my_lib.sh
source ~/.config/shell/lib/logos.sh

print_logo_system_update

# Update the system with pacman
print_h2 "Updating system with pacman"
sudo pacman -Syu --noconfirm

# Update the AUR packages with yay
print_h2 "Updating AUR packages with yay"
yay --noconfirm

# Remove unused packages (autoclean)
print_h2 "Pacman autocleaning"
# check if there are packages to clean
if pacman -Qdtq; then
    sudo pacman -Rcns $(pacman -Qdtq)
else
    print_note "nothing to clean"
fi

print_h2 "Remove yay and pacman cache"
yay -Scc --noconfirm

# Update flatpak applications
print_h2 "Updating flatpak applications"
flatpak update -y
