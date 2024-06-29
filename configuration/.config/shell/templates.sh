#!/bin/bash

# Ensure the ~/Templates directory exists
TEMPLATE_DIR="$HOME/Templates"
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template directory $TEMPLATE_DIR does not exist."
    exit 1
fi

# Use fzf to select a file or symlink from the ~/Templates directory
selected_file=$(find "$TEMPLATE_DIR" -type f -o -type l | fzf --height=10 --reverse --border)

# Check if a file was selected
if [ -z "$selected_file" ]; then
    echo "No file selected."
    exit 1
fi

# If the selected file is a symlink, copy the target of the symlink
if [ -L "$selected_file" ]; then
    target_file=$(readlink -f "$selected_file")
    if [ ! -f "$target_file" ]; then
        echo "The target of the symlink $selected_file does not exist or is not a regular file."
        exit 1
    fi
    cp "$target_file" .
    echo "Copied $(basename "$target_file") to $(pwd) (target of symlink)"
else
    cp "$selected_file" .
    echo "Copied $(basename "$selected_file") to $(pwd)"
fi
