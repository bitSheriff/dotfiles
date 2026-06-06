set shell := ["bash", "-uc"]

HOSTNAMES := "rhodos delos"

default:
    just choose

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
