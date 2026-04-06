#!/bin/bash
# Format JSON proper;y
JSON=$(hyprkeys --from-ctl --json | jq -r --slurp "[.[]][0]");

USER_SELECTED=$(echo $JSON | jq -r '.[] | "\(.mods) \(.key) \(.dispatcher) \(.arg)"' | wofi --dmenu -p 'Keybinds' --define "dmenu-print_line_num=true");

if [ -z "$USER_SELECTED" ]; then
    exit 0;
fi

EVENT=$(echo $JSON | jq -r "[.[]] | .[$USER_SELECTED]" | jq -r '"\(.dispatcher) \(.arg)"');

hyprctl dispatch "$EVENT";
