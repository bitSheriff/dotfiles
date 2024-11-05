#!/bin/bash

# install (update) hyprpm, the plugin manager
hyprpm update --no-shallow

# install easy motion
hyprpm add https://github.com/zakk4223/hyprland-easymotion

hyprpm enable hyprEasymotion
