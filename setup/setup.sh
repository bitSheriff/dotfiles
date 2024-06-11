#!/bin/bash

PACMAN_FLAGS="-S --needed"
YAY_FLAGS="-S --needed"

# get the arguemnts
ARGV=("$@")
ARG_MODE=("${ARGV[0]}")

DO_BACKUP=0
INSTALL_BACKUP=0
DO_SYMLINKS=0

do_backup(){
	echo "Backing up installed packages"
	pacman -Qqen > pkglist.txt
	pacman -Qqem > pkglist_aur.txt
}

install_from_backup(){
	pacman "$PACMAN_FLAGS" - < pkglist.txt
	yay "$YAY_FLAGS" - < pkglist_aur.txt
}

create_symlinks(){

	# Hyprland specific packages
    ln -sf ~/.config/dunst/ ../dunst/
    ln -sf ~/.config/fuzzel ../fuzzel
    ln -sf ~/.config/hypr ../hypr
    ln -sf ~/.config/kitty ../kitty
    ln -sf ~/.config/peaclock ../peaclock
    ln -sf ~/.config/qt6ct ../qt6ct
    ln -sf ~/.config/shell ../shell
    ln -sf ~/.config/theming ../theming
    ln -sf ~/.config/wallpapers ../wallpapers
    ln -sf ~/.config/waybar ../waybar
    ln -sf ~/.config/waypaper ../waypaper
    ln -sf ~/.config/wlogout ../wlogout
    ln -sf ~/.config/wofi ../wofi

    # Development Environment
    ln -sf ~/.config/clang ../clang
    ln -sf ~/.config/git ../git
    ln -sf ~/.config/lazygit ../lazygit
    ln -sf ~/.config/nvim ../nvim
    ln -sf ~/.config/yazi ../yazi
    ln -sf ~/.config/zellij ../zellij

    # Additional ones for comfort
    ln -sf ~/Pictures/wallpapers ../wallpapers

}

if [[ ${#ARGV[@]} = 0 ]]; then
	echo "No arguements given: install the packages and link them"
	INSTALL_BACKUP=1
	DO_SYMLINKS=1
fi;

if [[ "$ARG_MODE" = 'all' ]]; then
	echo "Mode all selected"
	echo "Installing packages and linkt them"
	INSTALL_BACKUP=1
	DO_SYMLINKS=1
fi;

if [[ "$ARG_MODE" = 'backup' ]]; then
	DO_BACKUP=1
fi;

if [[ "$ARG_MODE" = 'install' ]]; then
	INSTALL_BACKUP=1
fi;

if [[ "$ARG_MODE" = 'links' ]]; then
	DO_SYMLINKS=1
fi;

######### ACTION ##########

if [[ "$DO_BACKUP" = 1 ]]; then
	do_backup
fi;

if [[ "$INSTALL_BACKUP" = 1 ]]; then
	install_from_backup
fi;

if [[ "$DO_SYMLINKS" = 1 ]]; then
	create_symlinks
fi;
