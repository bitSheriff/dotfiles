#!/bin/bash

# Check if CACHE_DIR environment variable is set, if not default to $HOME/.cache
CACHE_DIR="${CACHE_DIR:-$HOME/.cache}"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to write a cache option
write_cache_option() {
    local app_name=$1
    local option_name=$2
    local app_dir="$CACHE_DIR/$app_name"
    
    # Create application directory if it doesn't exist
    mkdir -p "$app_dir"
    
    # Create the option file
    touch "$app_dir/$option_name"
}

# Function to check a cache option
check_cache_option() {
    local app_name=$1
    local option_name=$2
    local app_dir="$CACHE_DIR/$app_name"
    
    # Check if the option file exists
    if [[ -f "$app_dir/$option_name" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to remove a cache option
remove_cache_option() {
    local app_name=$1
    local option_name=$2
    local app_dir="$CACHE_DIR/$app_name"
    
    # Remove the option file
    if [[ -f "$app_dir/$option_name" ]]; then
        rm "$app_dir/$option_name"
        echo "Cache option removed"
    else
        echo "Cache option does not exist"
    fi
}

# Function to store a value in a cache option
write_cache_value() {
    local app_name=$1
    local option_name=$2
    local value=$3
    local app_dir="$CACHE_DIR/$app_name"
    
    # Create application directory if it doesn't exist
    mkdir -p "$app_dir"
    
    # Write the value to the option file
    echo "$value" > "$app_dir/$option_name"
}

# Function to get a value from a cache option
read_cache_value() {
    local app_name=$1
    local option_name=$2
    local app_dir="$CACHE_DIR/$app_name"
    
    # Check if the option file exists and read its value
    if [[ -f "$app_dir/$option_name" ]]; then
        cat "$app_dir/$option_name"
    else
        echo "Cache option does not exist"
        return 1
    fi
}

# Example usage:
# write_cache_option MyApp option1
# check_cache_option MyApp option1
# remove_cache_option MyApp option1
# write_cache_value MyApp option1 "some_value"
# read_cache_value MyApp option1

