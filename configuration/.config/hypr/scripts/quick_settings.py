#!/usr/bin/env python3

import subprocess
import os

WOFI_SIZE = "--width=200 "
WOFI_OPTS = "--allow-images --insensitive --dmenu --prompt='Quick Settings' --sort-order=default"

# Same Order as in the Quick Settings Menu
appBundle = [
    ["🖼", "Wallpaper", "waypaper"],
    ["📺", "Monitor Settings", "nwg-displays"],
    ["💉", "Color Picker", "hyprpicker -a"],
    ["😀", "Emoji Picker", "jome | wl-copy"],
    ["🎧", "Audio Chooser", "~/.config/waybar/scripts/audio_changer.py"],
    ["⚡", "Power Menu", "wlogout"],
    ["🌗", "Night Mode", "hyprshade toggle blue-light-filter"],
]


def get_concat_name(i):
    return f"{appBundle[i][0]} {appBundle[i][1]}"

def get_selection():
    nameList = []
    for i in range(len(appBundle)):
        nameList.append(get_concat_name(i))

    selected = os.popen(f"echo \"%s\" | wofi {WOFI_OPTS} {WOFI_SIZE} --lines={len(appBundle)+1} -S dmenu"%("\n".join(nameList))).read()
    return selected.rstrip()


# main function
def main():

    selectedName = get_selection()

    for i in appBundle:
        i_name = get_concat_name(appBundle.index(i))
        if i_name == selectedName:
            print(f"Will call {i[2]}")
            os.system(i[2])


if __name__ == "__main__":
    main()
    exit()
