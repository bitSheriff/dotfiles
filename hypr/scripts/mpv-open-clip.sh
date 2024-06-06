#!/usr/bin/bash

# get the URL from the clipboard
URL="$(wl-paste -n)" 

# open the url in mpv
mpv $URL &
