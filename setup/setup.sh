#!/bin/bash

PACMAN_FLAGS=" --needed "
YAY_FLAGS=" --needed --answerdiff None "

# get the arguemnts
ARGV=("$@")
ARG_MODE=("${ARGV[0]}")

DO_BACKUP=0
INSTALL_BACKUP=0
DO_SYMLINKS=0

confirm() {
    # call with a prompt string or use a default
    read -r -p "$1 - [y/n]" response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

do_backup(){
	echo "Backing up installed packages"
	pacman -Qqen > pkglist.txt
	pacman -Qqem > pkglist_aur.txt
}

install_from_backup(){
	echo "Install Pacman Packages"
	sudo pacman $PACMAN_FLAGS -S - < pkglist.txt

	echo "Install AUR Packages"
	yay $YAY_FLAGS -S - < pkglist_aur.txt
}

create_symlinks(){

	# Hyprland specific packages
	ln -sf $(pwd)/../dunst/ ~/.config/dunst
	ln -sf $(pwd)/../fuzzel/ ~/.config/fuzzel
	ln -sf $(pwd)/../hypr/ ~/.config/hypr
	ln -sf $(pwd)/../kitty/ ~/.config/kitty
	ln -sf $(pwd)/../peaclock/ ~/.config/peaclock
	ln -sf $(pwd)/../qt6ct/ ~/.config/qt6ct
	ln -sf $(pwd)/../shell/ ~/.config/shell
	ln -sf $(pwd)/../theming/ ~/.config/theming
	ln -sf $(pwd)/../wallpapers/ ~/.config/wallpapers
	ln -sf $(pwd)/../waybar/ ~/.config/waybar
	ln -sf $(pwd)/../waypaper/ ~/.config/waypaper
	ln -sf $(pwd)/../wlogout/ ~/.config/wlogout
	ln -sf $(pwd)/../wofi/ ~/.config/wofi

	# Development Enviroment
	ln -sf $(pwd)/../clang/ ~/.config/clang
	ln -sf $(pwd)/../git/ ~/.config/git
	ln -sf $(pwd)/../lazygit/ ~/.config/lazygit
	ln -sf $(pwd)/../nvim/ ~/.config/nvim
	ln -sf $(pwd)/../yazi/ ~/.config/yazi
	ln -sf $(pwd)/../zellij/ ~/.config/zellij


	# Additional ones for comfort
	ln -sf $(pwd)/../wallpapers ~/Pictures/wallpapers

}

remove_symlinks() {
    find ~/.config -type l -print0 | xargs -0 rm -v

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

if [[ "$ARG_MODE" = 'unlink' ]]; then
	remove_symlinks
fi;

######### ACTION ##########

confirm "Would you like?" && echo "You said yes"

if [[ "$DO_BACKUP" = 1 ]]; then
	do_backup
fi;

if [[ "$INSTALL_BACKUP" = 1 ]]; then
	install_from_backup
fi;

if [[ "$DO_SYMLINKS" = 1 ]]; then
	echo "[WIP] nothing will happen"
	# create_symlinks # work in progress
fi;