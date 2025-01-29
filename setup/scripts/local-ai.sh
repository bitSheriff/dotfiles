#!/bin/bash

DIR_NAME=$(dirname "$0")
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/my_lib.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/logos.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/cache.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/distributions.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../../lib/package_manager.sh"

setup_models() {

    print_h3 "Setup Models"

    models=(
        "DeepSeek R1:7b"
    )

    # sort the packages
    IFS=$'\n' sorted_models=($(sort -V <<<"${models[*]}"))
    unset IFS

    # read the wanted apps
    selection=$(
        gum choose --no-limit "${sorted_models[@]}"
    )

    IFS=$'\n' read -rd '' -a array <<<"$selection"

    if array_contains "${array[@]}" "DeepSeek R1:7b"; then
        print_note "Pulling DeepSeek R1 7B-Version"
        print_note "~ 5GB"
        ollama pull deepseek-r1:7b
    fi
}

## -- MAIN -- ##

print_h2 "Local AI Setup"

# install ollama which is used to intract with different models
print_note "Setup ollama"
pacman_install_single "ollama"

# setup the different models
setup_models
