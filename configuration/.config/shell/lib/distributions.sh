#!/bin/bash

# Function to check if the system is Arch Linux
is_arch() {
    if [[ -f /etc/arch-release ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if the system is Debian-based (Debian or Ubuntu)
is_debian() {
    if [[ -f /etc/debian_version ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if the system is Fedora
is_fedora() {
    if [[ -f /etc/fedora-release ]]; then
        return 0
    else
        return 1
    fi
}
