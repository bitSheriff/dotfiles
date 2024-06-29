#!/bin/bash

# Ensure the ~/Templates directory exists
TEMPLATE_DIR="$HOME/Templates"
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template directory $TEMPLATE_DIR does not exist."
    exit 1
fi

# Use fd to recursively select only files and symlinks (excluding directories)
selected_file=$(fd --type f --type l --follow --exclude .git . "$TEMPLATE_DIR" | fzf --height=10 --reverse --border --bind 'tab:accept')

# Check if a file was selected
if [ -z "$selected_file" ]; then
    echo "No file selected."
    exit 1
fi

# Determine the actual file to copy if it's a symlink
if [ -L "$selected_file" ]; then
    target_file=$(readlink -f "$selected_file")
    if [ ! -f "$target_file" ]; then
        echo "The target of the symlink $selected_file does not exist or is not a regular file."
        exit 1
    fi
else
    target_file="$selected_file"
fi

# Prompt for a new filename
echo "Enter new filename (leave empty to use original name): "
read new_filename

# Set the destination filename
if [ -z "$new_filename" ]; then
    dest_filename=$(basename "$target_file")
else
    dest_filename="$new_filename"
fi

# Copy the file
cp "$target_file" "./$dest_filename"

echo "Copied $(basename "$target_file") to $(pwd) as $dest_filename"
