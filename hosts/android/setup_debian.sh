#!/usr/bin/env bash
# Setup for the Android Linux Terminal, the Debian VM shipped in Android 15+.
# Safe to run again on an already set up phone.
#
# This is the plain-Debian sibling of ./setup.sh (nix-on-droid), which is on ice
# until https://github.com/nix-community/nix-on-droid/issues/495 is fixed. No
# proot here: the terminal is a real VM, so apt and normal binaries just work.
#
# Bootstrap on a fresh VM:
#   sudo apt-get update && sudo apt-get install -y git
#   git clone https://github.com/bitSheriff/dotfiles.git ~/code/dotfiles
#   ~/code/dotfiles/hosts/android/setup_debian.sh

set -euo pipefail

# resolve the repo dir, so the script can be called from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# everything the .bashrc needs: fzf for every prompt, openssh-client for the
# notes remote, neovim for the nv alias.
#
# No gum: it is noticeably slower to start than fzf on the phone, and fzf
# --print-query covers the one thing gum filter --no-strict did that plain fzf
# does not (entering an account that is not in the list).
PACKAGES=(
    ca-certificates
    fd-find
    fzf
    git
    hledger
    hledger-ui
    less
    neovim
    openssh-client
)

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$1"; }

install_packages() {
    sudo apt-get update -y
    sudo apt-get install -y "${PACKAGES[@]}"
}

setup_local_bin() {
    mkdir -p ~/.local/bin

    # Debian ships fd as fdfind because of a name clash. The .bashrc copes
    # either way, but plenty of other things expect `fd`.
    if command -v fdfind >/dev/null 2>&1 && [ ! -e ~/.local/bin/fd ]; then
        ln -sf "$(command -v fdfind)" ~/.local/bin/fd
    fi
}

setup_bash() {
    ln -sf "${SCRIPT_DIR}/.bashrc" ~/.bashrc
}

# Android mounts shared storage into the VM under /mnt/shared. How much of it
# is visible depends on the Android version: 16 QPR2 exposes nearly all shared
# storage, older builds only Downloads. Rather than guess, look for the notes
# directory and record where it turned up.
setup_storage() {
    local candidates=(
        /mnt/shared/Documents/notes
        /mnt/shared/Download/notes
        /mnt/shared/Downloads/notes
        "${HOME}/notes"
    )

    mkdir -p ~/.config

    local dir
    for dir in "${candidates[@]}"; do
        if [ -d "${dir}" ]; then
            log "Found notes at ${dir}"
            echo "NOTES_DIR=${dir}" >~/.config/dotfiles-notes-path
            return
        fi
    done

    warn "No notes directory found. Looked in:"
    printf '     %s\n' "${candidates[@]}"
    if [ -d /mnt/shared ]; then
        warn "/mnt/shared currently contains:"
        find /mnt/shared -maxdepth 1 -mindepth 1 -printf '     %f\n' 2>/dev/null || true
        warn "Once the notes are there, re-run this script, or write the path"
        warn "into ~/.config/dotfiles-notes-path as NOTES_DIR=/full/path."
    else
        warn "/mnt/shared does not exist. Enable file sharing for the Terminal"
        warn "app in Android settings, then re-run."
    fi
}

setup_hledger() {
    mkdir -p ~/.config/hledger
    cat >~/.config/hledger/hledger.conf <<'EOF'
[check] --strict
[balancesheet] --layout=bare
EOF

    # hledger only learned to read hledger.conf in 1.40. Debian bookworm ships
    # 1.25 and trixie 1.32, so say so rather than let it silently do nothing.
    local version
    version="$(hledger --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)"
    if [ -n "${version}" ]; then
        log "hledger ${version}"
        if [ "$(printf '%s\n1.40\n' "${version}" | sort -V | head -1)" != "1.40" ]; then
            warn "hledger < 1.40 ignores ~/.config/hledger/hledger.conf."
            warn "Everything else works; only the default flags are lost."
        fi
    fi
}

setup_git() {
    git config --global user.name "bitSheriff"
    git config --global user.email "root@bitsheriff.dev"
    git config --global core.editor "nvim"
    git config --global init.defaultBranch "main"
    git config --global pull.rebase true
    git config --global rebase.autoStash true
    git config --global push.autoSetupRemote true

    # The notes live on a mount that reports a foreign owner, which git
    # otherwise refuses to touch.
    if [ -f ~/.config/dotfiles-notes-path ]; then
        # shellcheck disable=SC1090
        . ~/.config/dotfiles-notes-path
        git config --global --replace-all safe.directory "${NOTES_DIR}"
    fi
}

setup_ssh() {
    local key=~/.ssh/id_ed25519

    if [ ! -f "${key}" ]; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -C "debian@android" -f "${key}" -N ""
    fi

    log "Public key, add it to Forgejo before running bkinit:"
    cat "${key}.pub"
}

log "Installing packages"
install_packages

log "Setting up ~/.local/bin"
setup_local_bin

log "Linking .bashrc"
setup_bash

log "Locating shared storage"
setup_storage

log "Configuring hledger"
setup_hledger

log "Setting up git"
setup_git

log "Setting up ssh"
setup_ssh

log "Done. Run 'exec bash -l' or open a new session to pick up the .bashrc."
