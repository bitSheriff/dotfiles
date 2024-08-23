#!/bin/bash

# Ensure the ~/Templates directory exists
TEMPLATE_DIR="$HOME/Templates"

# Function to copy file content to clipboard using wl-copy
copy_content_to_clipboard() {
    local file="$1"
    # Check if the file is a symlink
    if [ -L "$file" ]; then
        file=$(readlink -f "$file")
    fi

    # Check if the file exists and is a regular file
    if [ -f "$file" ]; then
        cat "$file" | wl-copy
        echo "Content of $(basename "$file") copied to clipboard."
    else
        echo "Error: The selected file $file does not exist or is not a regular file."
        exit 1
    fi
}

# Use fd to recursively select only files and symlinks (excluding directories)
export FZF_DEFAULT_COMMAND="fd . $TEMPLATE_DIR"
selected_file=$(fd --type f --type l --follow --exclude .git . "$TEMPLATE_DIR" | fzf --height=10 --reverse --border --bind 'ctrl-c:abort,esc:abort,tab:accept')

#######################################
##########   MAIN   ###################
#######################################

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template directory $TEMPLATE_DIR does not exist."
    exit 1
fi

# Check if a file was selected
if [ -z "$selected_file" ]; then
    echo "No file selected. Exiting."
    exit 0
fi

# Determine if --clip option is provided
if [ "$1" = "--clip" ]; then
    # Copy content to clipboard
    copy_content_to_clipboard "$selected_file"
else
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
fi

exit 0
