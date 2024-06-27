#!/bin/bash

VERSION="R2024a"
PRODUCTS="MATLAB"
DESTINATION="$HOME/Applications/Matlab_$VERSION"

# download the installer
wget -P "$HOME/Downloads" https://www.mathworks.com/mpm/glnxa64/mpm

# make it executable
chmod +x "$HOME/mpm"

# call the setup with version
bash "$HOME/Downloads/mpm" --release="$VERSION" --products "$PRODUCTS" --destination="$DESTINATION"

# create desktop file

echo "[Desktop Entry]
Type=Application
Terminal=false
MimeType=text/x-matlab
Exec=$DESTINATION/bin/matlab -desktop
Name=MATLAB
Icon=matlab
Categories=Development;Math;Science
Comment=Scientific computing environment
StartupNotify=true
" > /usr/share/applications/matlab.desktop
