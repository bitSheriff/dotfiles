#!/usr/bin/env bash
# Bootstrap for the Android host, safe to run again on an already set up phone.
#
# This used to `pkg install` a package list and symlink dotfiles by hand. It
# does none of that any more: packages, .bashrc, termux.properties, the git
# config and the shortcuts are all declared in ./default.nix and ./home.nix and
# applied by `nix-on-droid switch`.
#
# What is left here is what Nix cannot do for us:
#   * clone the dotfiles, because the flake has to exist before it can be built
#   * ask Android for the storage permission
#   * generate the SSH key, because a private key must not live in the store
#
# Run it inside the nix-on-droid app:
#   bash <(curl -sL https://.../setup.sh)   or, once cloned:
#   ./hosts/android/setup.sh

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/bitSheriff/dotfiles.git}"
DOTFILES_PATH="${DOTFILES_PATH:-${HOME}/code/dotfiles}"
CONFIG_NAME="${CONFIG_NAME:-android}"

# The notes directory lives on the Android documents mount, which only exists
# after the storage permission has been granted.
NOTES_DIR="${HOME}/storage/documents/notes"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$1"; }

enable_flakes() {
    # nix-on-droid ships without flakes enabled, and the very first build has
    # to be a flake build. Once the config is active, ./default.nix keeps this
    # in /etc/nix/nix.conf; this file is only the seed.
    local conf="${HOME}/.config/nix/nix.conf"

    if ! grep -qs "experimental-features" "${conf}" 2>/dev/null; then
        mkdir -p "$(dirname "${conf}")"
        echo "experimental-features = nix-command flakes" >>"${conf}"
    fi
}

clone_dotfiles() {
    if [ -d "${DOTFILES_PATH}/.git" ]; then
        log "Dotfiles already present, pulling"
        nix run nixpkgs#git -- -C "${DOTFILES_PATH}" pull --ff-only || warn "pull failed, continuing with what is on disk"
        return
    fi

    log "Cloning dotfiles into ${DOTFILES_PATH}"
    mkdir -p "$(dirname "${DOTFILES_PATH}")"
    nix run nixpkgs#git -- clone "${DOTFILES_REPO}" "${DOTFILES_PATH}"
}

setup_storage() {
    if [ -d "${HOME}/storage" ]; then
        log "Storage already set up"
    else
        log "Requesting storage permission"
        # Provided by android-integration.termux-setup-storage in
        # ./default.nix; on the very first run the config is not active yet, so
        # fall back to the app's own copy if the command is missing.
        if command -v termux-setup-storage >/dev/null 2>&1; then
            termux-setup-storage
        else
            warn "termux-setup-storage not on PATH yet; grant storage access in"
            warn "Android settings -> Apps -> Nix-on-Droid -> Permissions, then re-run."
            return
        fi
    fi

    if [ ! -d "${NOTES_DIR}" ]; then
        warn "${NOTES_DIR} does not exist yet."
        warn "Sync or clone the notes there, then run 'bkinit'."
    fi
}

switch() {
    log "Building ${CONFIG_NAME}"
    nix-on-droid switch --flake "${DOTFILES_PATH}#${CONFIG_NAME}"
}

setup_ssh() {
    local key="${HOME}/.ssh/id_ed25519"

    if [ ! -f "${key}" ]; then
        log "Generating SSH key"
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        ssh-keygen -t ed25519 -C "nix-on-droid@android" -f "${key}" -N ""
    fi

    log "Public key, add it to Forgejo before running bkinit:"
    cat "${key}.pub"
}

enable_flakes
clone_dotfiles
setup_storage
switch
setup_ssh

log "Done. Open a new session, then use 'dots-switch' for future rebuilds."
