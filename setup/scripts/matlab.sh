#!/bin/bash

DIR_NAME=$(dirname "$0")
source "$DIR_NAME/../../lib/my_lib.sh"
source "$DIR_NAME/../../lib/logos.sh"
source "$DIR_NAME/../../lib/cache.sh"
source "$DIR_NAME/../../lib/distributions.sh"

VERSION="R2024b"
PRODUCTS="MATLAB"
DESTINATION="$HOME/Applications/Matlab_$VERSION"

# install needed packages for Matlab
sudo pacman -S libxcrypt libxcrypt-compat libcrypt libcrypt-compat

if [ -f "$HOME/Downloads/mpm" ]; then
    print_note "Matlab Package Manager already downloaded"
else
    # download the installer
    wget -P "$HOME/Downloads" https://www.mathworks.com/mpm/glnxa64/mpm
fi

# make it executable
chmod +x "$HOME/Downloads/mpm"

# call the setup with version
"$HOME/Downloads/mpm" install --release="$VERSION" --products "$PRODUCTS" --destination="$DESTINATION"

gum confirm --default=false "Install Simulink?" && (
    "$HOME/Downloads/mpm" install --release="$VERSION" --products "Simulink" --destination="$DESTINATION"
)

# create desktop file (not needed anymore, does the setup)

# echo "[Desktop Entry]
# Type=Application
# Terminal=false
# MimeType=text/x-matlab
# Exec=$DESTINATION/bin/matlab -desktop
# Name=MATLAB
# Icon=matlab
# Categories=Development;Math;Science
# Comment=Scientific computing environment
# StartupNotify=true
# " > "$HOME/.local/share/applications/matlab.desktop"
