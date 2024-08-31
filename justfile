set shell := ["bash", "-uc"]

default: update

# Update the configuration and the whole system
update:
    # pull the newest changes
    @git pull

    # link the new files
    @bash setup/setup.sh link

    # update zsh
    @exec zsh

    # start a system update
    @bash ~/bin/sysupdate

# Encrypt the secrets
encrypt:
    #!/bin/bash
    cd setup
    # encrypt the secrets and the ssh hosts
    op run -- bash ./setup.sh encrypt

# Decrypt the secrets
decrypt:
    #!/bin/bash
    cd setup
    # decrypt the secrets and ssh hosts
    op run -- bash ./setup.sh decrypt


# Commit the new changes
commit:
    # Encrypt the new stuff
    @just encrypt

    # add the changed files
    @git add -U

    # open lazygit to view the changes
    @lazygit
