local startup = {
    -- Propagate Hyprland's *full* environment (PATH, XDG_DATA_DIRS, etc.),
    -- not just WAYLAND_DISPLAY/XDG_CURRENT_DESKTOP. Without --all, systemd's
    -- user manager (and anything it D-Bus-activates, e.g. the xdg-desktop-
    -- portal URL opener) keeps whatever stale XDG_DATA_DIRS it booted with,
    -- which is missing /etc/profiles/per-user/$USER/share (home-manager's
    -- profile, e.g. Firefox). That silently breaks default-app resolution:
    -- the portal falls back to whatever *is* still visible in the stale env
    -- (e.g. qutebrowser, installed system-wide via environment.systemPackages).
    "dbus-update-activation-environment --systemd --all",
    "systemctl --user import-environment",
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