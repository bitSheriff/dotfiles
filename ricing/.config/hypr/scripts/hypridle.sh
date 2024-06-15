#!/bin/bash
#  _   _                  _     _ _      
# | | | |_   _ _ __  _ __(_) __| | | ___ 
# | |_| | | | | '_ \| '__| |/ _` | |/ _ \
# |  _  | |_| | |_) | |  | | (_| | |  __/
# |_| |_|\__, | .__/|_|  |_|\__,_|_|\___|
#        |___/|_|                        
# 

SERVICE="hypridle"
if [[ "$1" == "status" ]]; then
    sleep 1
    if pgrep -x "$SERVICE" >/dev/null ;then
        echo '{"text": "", "class": "notactive", "tooltip": "Screen locking deactivated"}'
    else
        echo '{"text": "", "class": "active", "tooltip": "Screen locking active"}'
    fi
fi
if [[ "$1" == "toggle" ]]; then
    if pgrep -x "$SERVICE" >/dev/null ;then
        killall hypridle
    else
        hypridle
    fi
fi
