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
        input = {
          kb_layout = "de";
          kb_options = "caps:escape";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
            clickfinger_behavior = true;
          };
        };

        cursor = {
          hide_on_key_press = true;
        };

        device = [
          {
            name = "zsa-technology-labs-voyager";
            kb_layout = "us";
            kb_variant = "intl";
            kb_options = "compose:ralt";
          }
        ];

        monitor = [
          ",preferred,auto,1"
          "desc:BOE 0x0BCA, 2256x1504@59.999, 0x0, 1"
        ];

        bindl = [
          ",switch:on:Lid Switch,exec,systemctl suspend"
        ];
      };
    };
}
