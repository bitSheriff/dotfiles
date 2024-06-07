#!/bin/bash

PAUSED="dunstctl is-paused"
TOGGLE="dunstctl set-paused toggle"

if [[ "$1" == "status" ]]; then
    if dunstctl is-paused | grep false > /dev/null ;then
        echo '{"text":" 󰂞"}'
        # "ﮡ"
    else
        echo '{"text": " 󰂠" }'
    fi
fi
if [[ "$1" == "toggle" ]]; then
    # exec "$TOGGLE"
    dunstctl set-paused toggle
fi
