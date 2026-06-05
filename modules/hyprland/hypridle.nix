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
      services.hypridle = {
        enable = false;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "hyprlock";
          };

          listener = [
            {
              timeout = 1200;
              on-timeout = "hyprlock";
              on-resume = "notify-send \"Welcome back!\"";
            }
            {
              timeout = 3600;
              on-timeout = "hyprctl dispatch 'hl.dsp.dpms({action = \"off\"})'";
              on-resume = "hyprctl dispatch 'hl.dsp.dpms({action = \"on\"})'";
            }
          ];
        };
      };
    };
}
