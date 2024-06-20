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
# check if there are packages to clean
if pacman -Qdtq; then
  sudo pacman -Rcns $(pacman -Qdtq)
else
  echo "nothing to clean"
fi

# Update flatpak applications
echo "Updating flatpak applications..."
flatpak update -y
echo "\n\n"


