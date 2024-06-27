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
