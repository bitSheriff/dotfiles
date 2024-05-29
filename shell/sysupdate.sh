#!/bin/bash 

# Update the system with pacman
echo "Updating system with pacman..."
sudo pacman -Syu --noconfirm
echo "\n\n"

# Update the AUR packages with yay
echo "Updating AUR packages with yay..."
yay -Syu --noconfirm
echo "\n\n"

# Remove unused packages (autoclean)
echo "Pacman autocleaning..."
sudo pacman -R $(pacman -Qdtq)

# Update flatpak applications
echo "Updating flatpak applications..."
flatpak update -y
echo "\n\n"


