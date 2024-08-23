#!/bin/bash

# Name of the virtual environment directory
VENV_DIR=".venv"

# Check if the virtual environment already exists
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists."
else
    # Create virtual environment
    echo "Creating virtual environment..."
    python3 -m venv $VENV_DIR

    # Check if requirements.txt exists and install packages
    if [ -f "requirements.txt" ]; then
        echo "Installing packages from requirements.txt..."
        $VENV_DIR/bin/pip install -r requirements.txt
    else
        echo "requirements.txt not found, skipping package installation."
    fi
fi

# Activate the virtual environment
echo "Activating the virtual environment..."
source $VENV_DIR/bin/activate

# Keep the shell in the activated environment
exec "$SHELL"
