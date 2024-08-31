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
    (cd $DOTFILES_DIR/configuration/.config/nvim/ && lazygit)

    # wallpapers
    (cd $DOTFILES_DIR/configuration/.config/wallpapers/ && lazygit)

    # secrets
    if [ -d "$DOTFILES_DIR/secrets" ]; then \
        (cd "$DOTFILES_DIR/secrets" && lazygit) \
    fi
 
    # main repository
    lazygit
