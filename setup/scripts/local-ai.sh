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
        "DeepSeek R1:14b"
        "Mistral"
        "gpt-oss:20b"
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
        print_note "~4.7GB"
        ollama pull deepseek-r1:7b
    fi

    if array_contains "${array[@]}" "DeepSeek R1:14b"; then
        print_note "Pulling DeepSeek R1 14B-Version"
        print_note "~9GB"
        ollama pull deepseek-r1:14b
    fi

    if array_contains "${array[@]}" "Mistral"; then
        print_note "Pulling Mistral"
        print_note "~4.1GB"
        ollama pull mistral
    fi

    if array_contains "${array[@]}" "gpt-oss:20b"; then
        print_note "Pulling GPT-oss 20b"
        print_note "~13GB"
        ollama pull gpt-oss:20b
    fi

}

## -- MAIN -- ##

print_h2 "Local AI Setup"

# install ollama which is used to intract with different models
print_note "Setup ollama"
pacman_install_single "ollama"
# enable and start the service
sudo systemctl enable ollama
sudo systemctl start ollama

# setup the different models
setup_models
