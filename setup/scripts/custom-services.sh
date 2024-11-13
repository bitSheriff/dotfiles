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

servs=("git-auto-fetch")

# read the wanted apps
selection=$(
    gum choose --no-limit "${servs[@]}"
)

IFS=$'\n' read -rd '' -a array <<<"$selection"

if array_contains "${array[@]}" "git-auto-fetch"; then
    print_h3 "git-auto-fetch"

    # activate the service
    systemctl --user daemon-reload
    systemctl --user enable git-auto-fetch.timer
    systemctl --user start git-auto-fetch.timer
fi
