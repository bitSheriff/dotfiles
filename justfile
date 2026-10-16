set shell := ["bash", "-uc"]

HOSTNAMES := "rhodos delos"

default:
    just --choose

# build the phone config (inside nix-on-droid) or install its F-Droid apps
# over ADB (anywhere else); see setup-android in scrips.nix for the logic.
android:
    DOTFILES_DIR={{ justfile_directory() }} nix run {{ justfile_directory() }}#setup-android

# link the current dotfile directory to /etc/nixos
link:
    @echo "Link dotfiles"
    @sudo rm -rf /etc/nixos
    @sudo ln -s $(pwd) /etc/nixos

# only for the fresh install on a new device
setup:
    #! /bin/bash
    hostname=$(gum choose {{ HOSTNAMES }})
    echo "Copying the auto generated hardware config"
    cp /etc/nixos/hardware-configuration.nix ./hosts/$hostname/
    echo "Deleting original NixOS configuration and link new one"
    sudo rm -rf /etc/nixos
    sudo ln -s $(pwd) /etc/nixos
    echo "Installing the NixOS configuration"
    sudo nixos-rebuild switch --flake /etc/nixos#$hostname
