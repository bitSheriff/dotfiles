#!/bin/bash 

# Update the system with pacman
echo "Updating system with pacman..."
sudo pacman -Syu --noconfirm

# Update the AUR packages with yay
echo "Updating AUR packages with yay..."
yay -Syu --noconfirm

# Update flatpak applications
echo "Updating flatpak applications..."
flatpak update -y


