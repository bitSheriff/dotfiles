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

# install (update) hyprpm, the plugin manager
print_note "Updating existing plugins"
hyprpm update --no-shallow

plugins=("easymotion")

echo -e "\n\n"
echo -e "$BOLD_BLUE" "easymotion" "$NC" "\tbetter window switching with vim-like hotkey switching"

# read the wanted apps
selection=$(
    gum choose --no-limit "${plugins[@]}"
)

IFS=$'\n' read -rd '' -a array <<<"$selection"

if array_contains "${array[@]}" "easymotion"; then
    print_h2 "easymotion"
    # install easy motion
    hyprpm add https://github.com/zakk4223/hyprland-easymotion

    hyprpm enable hyprEasymotion

fi
