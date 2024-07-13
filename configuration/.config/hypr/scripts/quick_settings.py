#!/usr/bin/env python3

import subprocess
import os

WOFI_SIZE = "--width=450 --height=180"
WOFI_OPTS = "--allow-iamges --insensitive"

appBundle = [
    ["🖼", "Waypaper", "waypaper"],
    ["📺", "Monitor", "nwg-displays"]
]

def get_concat_name(i):
    return f"{appBundle[i][0]} {appBundle[i][1]}"

def get_selection():
    nameList = []
    for i in range(len(appBundle)):
        nameList.append(get_concat_name(i))

    selected = os.popen(f"echo \"%s\" | wofi {WOFI_OPTS} {WOFI_SIZE} -S dmenu"%("\n".join(nameList))).read()
    return selected.rstrip()


def main():
    # main function

    selectedName = get_selection()

    for i in appBundle:
        i_name = get_concat_name(appBundle.index(i))
        if i_name == selectedName:
            print(f"Will call {i[2]}")
            os.system(i[2])


if __name__ == "__main__":
    main()
    exit()
