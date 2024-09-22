#!/bin/bash

DOWNLOAD="https://www.maplesoft.com/downloads/?d=748C0914157F9B13F768F9960311FCF9&v=4&f=Maple2023.2LinuxX64Installer.run" # Version 2023

# download the installer
wget -P "$HOME/Downloads" "$DOWNLOAD"

# make it executable
chmod +x "$HOME/Downloads/Maple2023.2LinuxX64Installer.run"

# start the installer
bash "$HOME/Downloads/Maple2023.2LinuxX64Installer.run"
