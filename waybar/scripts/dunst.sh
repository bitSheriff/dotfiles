#!/bin/bash

PAUSED="dunstctl is-paused"
TOGGLE="dunstctl set-paused toggle"

if [[ "$1" == "status" ]]; then
    sleep 1
    if dunstctl is-paused | grep false ;then
        echo '{"text": "" }'
    else
        echo '{"text": "ﮡ" }'
    fi
fi
if [[ "$1" == "toggle" ]]; then
    # exec "$TOGGLE"
    dunstctl set-paused toggle
fi
