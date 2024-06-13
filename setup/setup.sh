#!/bin/bash

PACMAN_FLAGS=" --needed "
YAY_FLAGS=" --needed --answerdiff None --answerclean None "

# get the arguemnts
ARGV=("$@")
ARG_MODE=("${ARGV[0]}")

DO_BACKUP=0
INSTALL_BACKUP=0
DO_SYMLINKS=0

DO_DEV=0
DO_OFFICE=0
DO_HYPR=0

confirm() {
    # call with a prompt string or use a default
    read -r -p "$1 - [y/n] " response
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

pacman_install(){
	grep -o "^[^#]*" "$1" | sudo pacman $PACMAN_FLAGS -S -
}

yay_install(){
	grep -o "^[^#]*" "$1" | yay $YAY_FLAGS -S -
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

setup_shell(){

	# set zsh as default shell
	chsh -s /bin/zsh

}

install_hyprland(){

	echo "[Hyprland] Install Pacman Packages"
	pacman_install pkglist_hyprland.txt

	echo "[Hyprland] Install AUR Packages"
	yay_install pkglist_hyprland_aur.txt

	setup_shell
}

install_dev_tools(){

	echo "[Development] Install Pacman Packages"
	pacman_install  pkglist_dev.txt

	echo "[Development] Install AUR Packages"
	yay_install pkglist_dev_aur.txt
}

install_office_tools(){

	echo "[Office] Install Pacman Packages"
	pacman_install  pkglist_office.txt

	echo "[Office] Install AUR Packages"
	yay_install pkglist_office_aur.txt
}

selective_installation(){


	confirm "Would you like to install Hyprland & Co?" && DO_HYPR=1

	confirm "Would you like to install the Development Tools?" && DO_DEV=1

	confirm "Would you like to install the Office Tools?" && DO_OFFICE=1


    if [[ "$DO_HYPR" = 1 ]]; then
        install_hyprland
    fi;

    if [[ "$DO_DEV" = 1 ]]; then
        install_dev_tools
    fi;

    if [[ "$DO_OFFICE" = 1 ]]; then
        install_office_tools
    fi;

}

if [[ ${#ARGV[@]} = 0 ]]; then
	echo "No arguements given: start selective installation"
	selective_installation
	exit 0
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

confirm "Would you like a selective installation process?" && selective_installation

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
