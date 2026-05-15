{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  dotfiles_path,
  ...
}:

{
  home-manager.users.benjamin =
    { config, lib, ... }:
    lib.mkIf (lib.elem "benjamin" activeUsers) {
      wayland.windowManager.hyprland.settings = {
        exec-once = [
          "hyprpaper"
          "hypridle"
          "wl-clipboard"
          "blueman-applet"
          "nm-applet --indicator"
          "qs -c noctalia-shell"
          "noctalia-shell"
          "systemctl --user start hyprpolkitagent"
          "udiskie &"
          "wl-clipboard-history -t"
          "dunst"
          "waypaper --restore"
          "1password --silent"
          "hyprpm reload -n"
          "hyprsunset"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "XDG_MENU_PREFIX=arch- kbuildsycoca6"
          "gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'"
        ];
      };
    };
}
