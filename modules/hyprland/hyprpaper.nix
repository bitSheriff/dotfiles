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
      services.hyprpaper = {
        enable = false;
        settings = {
          ipc = "on";
          splash = false;
          wallpaper = [
            ",~/Pictures/wallpapers/desktop-wallpaper"
          ];
        };
      };
    };
}
