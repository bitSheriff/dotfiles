set shell := ["bash", "-uc"]

HOSTNAMES := "rhodos delos"

# build the phone config; run this on the phone itself, inside nix-on-droid
android:
    nix-on-droid switch --flake {{ justfile_directory() }}#android

# check that the phone config still evaluates, from any machine.
# --impure because nix-on-droid's bootstrap uses builtins.storePath, and this
# stops short of the activation package, whose aarch64 proot binary cannot be
# substituted off-device.
android-check:
    nix eval --impure --json .#nixOnDroidConfigurations.android.config.environment.packages --apply 'ps: map (p: p.name) ps'

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
