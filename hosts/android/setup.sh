#! /data/data/com.termux/files/usr/bin/bash
# Setup script for the Termux host, safe to run again on an already set up phone.

set -euo pipefail

# resolve the repo dir, so the script can be called from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# everything the .bashrc needs: fzf for clkin/clkout, openssh for the notes
# remote, inetutils for the ping in bknotes, neovim for the nv alias
PACKAGES=(
    fd
    fzf
    git
    gum
    inetutils
    neovim
    openssh
    termux-api
    hledger
)

setup_bash() {
    ln -sf "${SCRIPT_DIR}/.bashrc" ~/.bashrc
}

setup_termux() {
    if [ ! -d ~/storage ]; then
        termux-setup-storage
    fi

    mkdir -p ~/.termux
    ln -sf "${SCRIPT_DIR}/termux.properties" ~/.termux/termux.properties
    termux-reload-settings
    setup_shortcuts
}

install_packages() {
    pkg update -y && pkg upgrade -y

    pkg install -y "${PACKAGES[@]}"

}

setup_git() {
    git config --global user.name "bitSheriff"
    git config --global user.email "root@bitsheriff.dev"
    git config --global core.editor "nvim"
    git config --global init.defaultBranch "main"
    git config --global pull.rebase true
    git config --global rebase.autoStash true
    git config --global push.autoSetupRemote true
}

setup_ssh() {
    local key=~/.ssh/id_ed25519

    if [ ! -f "${key}" ]; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -C "termux@android" -f "${key}" -N ""
    fi

    echo "Public key, add it to Forgejo before running bkinit:"
    cat "${key}.pub"
}

setup_shortcuts() {
    # scripts for the Termux:Widget home screen widget
    mkdir -p ~/.shortcuts

    for shortcut in "${SCRIPT_DIR}"/shortcuts/*; do
        chmod +x "${shortcut}"
        ln -sf "${shortcut}" ~/.shortcuts/"$(basename "${shortcut}")"
    done
}

echo "Installing Packages"
install_packages

echo "Setting up bash"
setup_bash

echo "General Termux settings"
setup_termux

echo "Setting up git"
setup_git

echo "Setting up ssh"
setup_ssh
