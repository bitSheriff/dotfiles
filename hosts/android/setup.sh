#!/usr/bin/env bash
# Bootstrap for the Android host, safe to run again on an already set up phone.
#
# This used to `pkg install` a package list and symlink dotfiles by hand. It
# does none of that any more: packages, .bashrc, termux.properties, the git
# config and the shortcuts are all declared in ./default.nix and ./home.nix and
# applied by `nix-on-droid switch`.
#
# What is left here is what Nix cannot do for us:
#   * ask Android for the storage permission
#   * generate the SSH key, because a private key must not live in the store
#   * clone the repo locally, so the config can be edited on the phone
#
# The order matters. The switch runs FIRST, straight from the remote flake:
# Nix fetches a github: ref as a tarball and needs no git to do it, so the
# switch is what installs git. Fetching git separately beforehand would
# download and unpack a second, unpinned copy of nixpkgs -- ten quiet minutes
# under proot for something the switch provides anyway.
#
# Run it inside the nix-on-droid app:
#   bash <(curl -sL https://raw.githubusercontent.com/bitSheriff/dotfiles/master/hosts/android/setup.sh)

set -euo pipefail

DOTFILES_REMOTE="${DOTFILES_REMOTE:-github:bitSheriff/dotfiles}"
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

switch() {
    # Build from whatever is already on disk if this is a re-run, otherwise
    # from the remote, which needs no git.
    local flake="${DOTFILES_REMOTE}"
    if [ -d "${DOTFILES_PATH}/.git" ]; then
        flake="${DOTFILES_PATH}"
    fi

    log "Building ${CONFIG_NAME} from ${flake}"
    warn "This unpacks nixpkgs into the store, which is slow and silent under"
    warn "proot. Expect several minutes with no output, and keep the app in the"
    warn "foreground or Android will suspend it. --print-build-logs so at least"
    warn "the build steps are visible."

    nix-on-droid switch --print-build-logs --flake "${flake}#${CONFIG_NAME}"
}

setup_storage() {
    if [ -d "${HOME}/storage" ]; then
        log "Storage already set up"
    else
        log "Requesting storage permission"
        # Installed by the switch above (android-integration in ./default.nix).
        if command -v termux-setup-storage >/dev/null 2>&1; then
            termux-setup-storage
        else
            warn "termux-setup-storage still not on PATH. Grant storage access in"
            warn "Android settings -> Apps -> Nix-on-Droid -> Permissions, then re-run."
            return
        fi
    fi

    if [ ! -d "${NOTES_DIR}" ]; then
        warn "${NOTES_DIR} does not exist yet."
        warn "Sync or clone the notes there, then run 'bkinit'."
    fi
}

clone_dotfiles() {
    # Only so the config can be edited on the phone; the switch above did not
    # need it. git comes from the generation that was just activated.
    if [ -d "${DOTFILES_PATH}/.git" ]; then
        log "Dotfiles already present, pulling"
        git -C "${DOTFILES_PATH}" pull --ff-only || warn "pull failed, keeping what is on disk"
        return
    fi

    log "Cloning dotfiles into ${DOTFILES_PATH}"
    mkdir -p "$(dirname "${DOTFILES_PATH}")"
    git clone "${DOTFILES_REPO}" "${DOTFILES_PATH}"
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
switch
setup_storage
clone_dotfiles
setup_ssh

log "Done. Open a new session, then use 'dots-switch' for future rebuilds."
