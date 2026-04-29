set shell := ["bash", "-uc"]

default:
    just choose

# link the current dotfile directory to /etc/nixos
link:
    (cd .. && sudo ln -s $(pwd)/dotfiles /etc/nixos)
