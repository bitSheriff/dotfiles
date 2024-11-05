set shell := ["bash", "-uc"]

default: update

# Update the configuration and the whole system
update:
    # pull the newest changes
    @git pull
    @git submodule update

    # link the new files
    @bash setup/setup.sh link

    # update zsh
    @exec zsh

    # start a system update
    @bash ~/bin/sysupdate

# (depricated) Encrypt the secrets
encrypt:
    #!/bin/bash
    cd setup
    # encrypt the secrets and the ssh hosts
    op run -- bash ./setup.sh encrypt

# (depricated) Decrypt the secrets
decrypt:
    #!/bin/bash
    cd setup
    # decrypt the secrets and ssh hosts
    op run -- bash ./setup.sh decrypt


# Commit the new changes
commit:
    # add the changed files
    @git add -U

    # open lazygit to view the changes
    @lazygit

# Commit in all directories
commit-all:
    # nvim
    @if [[ -n $(git -C $DOTFILES_DIR/configuration/.config/nvim/ status --porcelain) ]]; then \
        (cd $DOTFILES_DIR/configuration/.config/nvim/ && lazygit) \
    fi

    # wallpapers
    @if [[ -n $(git -C $DOTFILES_DIR/wallpapers/ status --porcelain) ]]; then \
        (cd $DOTFILES_DIR/wallpapers/ && lazygit) \
    fi

    # secrets
    @if [ -d "$DOTFILES_DIR/secrets" ]; then \
        if [[ -n $(git -C "$DOTFILES_DIR/secrets" status --porcelain) ]]; then \
            (cd "$DOTFILES_DIR/secrets" && lazygit) \
        fi \
    fi
 
    # main repository
    lazygit

# Backup to different gits
backup:
    @# add a timeout if a local git server cannot be reached
    timeout 30s git backup

# Check the Setup
check:
    # Check the Main Setup
    shellcheck ./setup/setup.sh
    shellcheck ./setup/scripts/hardware.sh
    shellcheck ./setup/scripts/languages.sh

    # Check the Libraries
    just --justfile ./lib/justfile check
