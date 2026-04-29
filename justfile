set shell := ["bash", "-uc"]

default:
    just choose

# link the current dotfile directory to /etc/nixos
link:
    @echo "Link dotfiles"
    @sudo rm -rf /etc/nixos
    @sudo ln -s $(pwd) /etc/nixos
