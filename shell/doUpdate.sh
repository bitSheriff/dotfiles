#!/bin/bash

varHostname=$(~/.config/tmux/scripts/getHostname.sh)

update_ubuntu()
{
  echo "Updating apt with nala"
  sudo nala update
  sudo nala upgrade 
}

update_fedora()
{
  echo "Updating dnf"
  sudo dnf update
}

update_flatpak()
{
  echo "Updating flatpaks"
  sudo flatpak update
}

update_snaps()
{
  echo "Updating snaps"
  sudo snap refresh
}

update_pacman()
{
  echo "Updating Pacman"
  sudo pacman -Syyu
}

update_yay()
{
  yay -Syyu
}

if varHostname=linuxlegion; then
  update_ubuntu
  update_flatpak
elif varHostname="0xdeadbeef"; then
  update_fedora
  update_flatpak
else
  echo "device $varHostname not found"
fi
