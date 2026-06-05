{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  dotfiles_path,
  ...
}:

let
  lua = lib.generators.mkLuaInline;
in
{
  home-manager.users.benjamin =
    { config, lib, ... }:
    lib.mkIf (lib.elem "benjamin" activeUsers) {
      wayland.windowManager.hyprland.settings = {
        on = {
          _args = [
            "hyprland.start"
            (lua ''
              function()
                hl.exec_cmd("hyprpaper")
                hl.exec_cmd("hypridle")
                hl.exec_cmd("wl-clipboard")
                hl.exec_cmd("blueman-applet")
                hl.exec_cmd("nm-applet --indicator")
                hl.exec_cmd("noctalia-shell")
                hl.exec_cmd("noctalia-shell")
                hl.exec_cmd("systemctl --user start hyprpolkitagent")
                hl.exec_cmd("udiskie &")
                hl.exec_cmd("wl-clipboard-history -t")
                hl.exec_cmd("dunst")
                hl.exec_cmd("waypaper --restore")
                hl.exec_cmd("1password --silent")
                hl.exec_cmd("hyprpm reload -n")
                hl.exec_cmd("hyprsunset")
                hl.exec_cmd("wl-paste --type text --watch cliphist store")
                hl.exec_cmd("wl-paste --type image --watch cliphist store")
                hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
                hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
                hl.exec_cmd("XDG_MENU_PREFIX=arch- kbuildsycoca6")
                hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'")
              end
            '')
          ];
        };
      };
    };
}
