#!/bin/bash

DIR_NAME=$(dirname "$0")

source "$DIR_NAME/../../lib/my_lib.sh"
source "$DIR_NAME/../../lib/logos.sh"
source "$DIR_NAME/../../lib/cache.sh"
source "$DIR_NAME/../../lib/distributions.sh"

print_h2 "Languages and langauge-specific Tooling"

# read the wanted languages
local selection=$(
    gum choose --no-limit \
        "Bash" \
        "C" \
        "LaTeX" \
        "Markdown" \
        "Python" \
        "Rust" \
        "Typst"
)

# Converting list from `gum choose` output to an array
IFS=$'\n' read -rd '' -a array <<<"$selection"

if array_contains "${array[@]}" "Bash"; then
    print_note "Language Bash"
    pacman_install_single "bash"
    pacman_install_single "bash-completion"
    pacman_install_single "bash-language-server"
fi

if array_contains "${array[@]}" "C"; then
    print_note "Language C"
    pacman_install_single "clang"
    pacman_install_single "cunit" # test-framework for c

    # CLI debugging Tools
    pacman_install_single "lldb"
    yay_install_single "codelldb"
fi

if array_contains "${array[@]}" "Markdown"; then
    print_note "Language Markdown"
    pacman_install_single "neovim"
    pacman_install_single "ghostwriter"
    # CLI Markdown Rederer
    pacman_install_single "glow"

    gum confirm --default=false "Install Hugo Server?" && pacman_install_single "hugo"
    gum confirm --default=false "Install Obsidian?" && yay_install_single "obsidian"
fi

if array_contains "${array[@]}" "Rust"; then
    print_note "Language Rust"

    # Language and LSP
    pacman_install_single "rustup"
    pacman_install_single "rust-analyzer"

    # CLI debugging Tools
    pacman_install_single "lldb"
    yay_install_single "codelldb"

    # optional IDE
    gum confirm --default=false "Install RustRover IDE?" && yay_install_single "rustrover"

    # set rust version
    rustup default stable

    # add the formatter component
    rustup component add rustfmt
    rustup component add clippy
fi

if array_contains "${array[@]}" "Python"; then
    print_note "Language Python"
    pacman_install_single "python"

    gum confirm --default=false "Install Qt Framework?" && (
        pacman_install_single "python-pyqt5"
        pacman_install_single "python-pyqt6"
    )

    gum confirm --default=false "Install PyCharm Community?" && pacman_install_single "pycharm-community-edition"

    gum confirm --default=false "Install Jupyter?" && pacman_install_single "jupyterlab"
fi

if array_contains "${array[@]}" "LaTeX"; then
    print_note "Language LaTeX"
    install_latex
fi

if array_contains "${array[@]}" "Typst"; then
    print_note "Language Typst"
    pacman_install_single "typst"
    pacman_install_single "typst-lsp"
fi
