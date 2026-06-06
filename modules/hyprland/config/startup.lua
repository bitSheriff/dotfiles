local startup = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "XDG_MENU_PREFIX=arch- kbuildsycoca6",
    "gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'",
    "hyprpaper &",
    "hypridle &",
    "wl-clipboard &",
    "blueman-applet &",
    "nm-applet --indicator &",
    "noctalia-shell &",
    "systemctl --user start hyprpolkitagent",
    "udiskie &",
    "wl-clipboard-history -t &",
    "dunst &",
    "1password --silent &",
    "wl-paste --type text --watch cliphist store &",
    "wl-paste --type image --watch cliphist store &"
}

hl.on("hyprland.start", function()
    for i = 1, #startup do
        hl.exec_cmd(startup[i])
    end
end)

hl.exec_cmd("waypaper --restore &")
hl.exec_cmd("hyprpm reload -n &")
hl.exec_cmd("hyprsunset &")