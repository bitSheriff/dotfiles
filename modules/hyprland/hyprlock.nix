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
      programs.hyprlock = {
        enable = false;
        settings = {
          general = {
            no_fade_in = false;
            grace = 0;
            disable_loading_bar = true;
          };

          background = [
            {
              monitor = "";
              path = "~/Pictures/wallpapers/desktop/synthwave/purple-sun.png";
              blur_passes = 0;
              contrast = 0.8916;
              brightness = 0.8172;
              vibrancy = 0.1696;
              vibrancy_darkness = 0.0;
            }
          ];

          label = [
            {
              monitor = "";
              text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
              color = "rgba(255, 255, 255, 0.6)";
              font_size = 100;
              font_family = "Comic Mono";
              position = "0, -20";
              halign = "center";
              valign = "top";
            }
            {
              monitor = "";
              text = "Hi there, $USER";
              color = "$foreground";
              font_size = 25;
              font_family = "JetBrainsMono NF Medium";
              position = "0, 20";
              halign = "center";
              valign = "center";
            }
            {
              monitor = "";
              text = "cmd[update:1000] echo \"$(~/.config/hypr/scripts/whatsong.sh)\"";
              color = "$foreground";
              font_size = 18;
              font_family = "JetBrainsMono NF ExtraBold, Font Awesome 6 Free Solid";
              position = "0, 40";
              halign = "center";
              valign = "bottom";
            }
          ];

          "input-field" = [
            {
              monitor = "";
              size = "400, 60";
              outline_thickness = 2;
              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;
              outer_color = "rgba(0, 0, 0, 0)";
              inner_color = "rgba(0, 0, 0, 0.5)";
              font_color = "rgb(200, 200, 200)";
              fade_on_empty = false;
              font_family = "JetBrainsMono NF Italic";
              placeholder_text = "<i><span foreground=\"##cdd6f4\">Input Password...</span></i>";
              hide_input = false;
              position = "0, -40";
              halign = "center";
              valign = "center";
            }
          ];

          auth = {
            fingerprint = {
              enabled = true;
            };
          };
        };
      };
    };
}
