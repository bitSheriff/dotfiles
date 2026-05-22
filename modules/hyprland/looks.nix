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
      wayland.windowManager.hyprland = {
        settings = {
          animations = {
            enabled = true;
            bezier = [
              "wind, 0.05, 0.9, 0.1, 1.05"
              "winIn, 0.1, 1.1, 0.1, 1.1"
              "winOut, 0.3, -0.3, 0, 1"
              "liner, 1, 1, 1, 1"
            ];
            animation = [
              "windows, 1, 6, wind, slide"
              "windowsIn, 1, 6, winIn, slide"
              "windowsOut, 1, 5, winOut, slide"
              "windowsMove, 1, 5, wind, slide"
              "border, 1, 1, liner"
              "borderangle, 1, 30, liner, loop"
              "fade, 1, 10, default"
              "workspaces, 1, 5, wind"
            ];
          };

          misc = {
            font_family = "Comic Mono";
            force_default_wallpaper = 0;
          };

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
          };

          plugin = {
            easymotion = {
              textsize = 20;
              textcolor = "rgba(ffffffff)";
              bgcolor = "rgba(000000ff)";
              textfont = "Sans";
              textpadding = "2 5 5 2";
              bordersize = 0;
              bordercolor = "rgba(ffffffff)";
              rounding = 0;
              motionkeys = "asdfghjklbgnh";
            };
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          decoration = {
            rounding = 10;
            active_opacity = 0.95;
            inactive_opacity = 0.9;
            fullscreen_opacity = 1.0;

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              # color = "$tertiary";
            };

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
          };

          workspace = [
            "special:term-scratchpad, on-created-empty:kitty --class term-scratchpad"
          ];
        };

        extraConfig = ''
          source = /home/benjamin/.config/hypr/noctalia/noctalia-colors.conf

          general {
            gaps_in = 5
            gaps_out = 5
            border_size = 2
            col.active_border = $primary $secondary 90deg
            col.inactive_border = $surface
            col.nogroup_border = rgba(282a36dd)
            col.nogroup_border_active = rgb(bd93f9) rgb(44475a) 90deg
            resize_on_border = false
            allow_tearing = false
            layout = dwindle
          }

          group {
            col.border_active = $secondary
            col.border_inactive = $surface
            col.border_locked_active = $error
            col.border_locked_inactive = $surface

            groupbar {
              enabled = true
              font_size = 12
              gradients = true
              height = 18
              priority = 3
              render_titles = true
              scrolling = true
              col.active = $secondary
              col.inactive = $surface
              col.locked_active = $error
              col.locked_inactive = $surface
              round_only_edges = false
              rounding_power = 3.0
              gradient_rounding = 5
              gaps_in = 1
              gaps_out = 1
            }
          }

        '';
      };

      # services.hypridle = {
      #   enable = true;
      #   settings = {
      #     general = {
      #       lock_cmd = "pidof hyprlock || hyprlock";
      #       before_sleep_cmd = "hyprlock";
      #     };
      #
      #     listener = [
      #       {
      #         timeout = 1200;
      #         on-timeout = "hyprlock";
      #         on-resume = "notify-send \"Welcome back!\"";
      #       }
      #       {
      #         timeout = 3600;
      #         on-timeout = "hyprctl dispatch dpms off";
      #         on-resume = "hyprctl dispatch dpms on";
      #       }
      #     ];
      #   };
      # };
      #
      # programs.hyprlock = {
      #   enable = true;
      #   settings = {
      #     general = {
      #       no_fade_in = false;
      #       grace = 0;
      #       disable_loading_bar = true;
      #     };
      #
      #     background = [
      #       {
      #         monitor = "";
      #         path = "~/Pictures/wallpapers/desktop/synthwave/purple-sun.png";
      #         blur_passes = 0;
      #         contrast = 0.8916;
      #         brightness = 0.8172;
      #         vibrancy = 0.1696;
      #         vibrancy_darkness = 0.0;
      #       }
      #     ];
      #
      #     label = [
      #       {
      #         monitor = "";
      #         text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
      #         color = "rgba(255, 255, 255, 0.6)";
      #         font_size = 100;
      #         font_family = "Comic Mono";
      #         position = "0, -20";
      #         halign = "center";
      #         valign = "top";
      #       }
      #       {
      #         monitor = "";
      #         text = "Hi there, $USER";
      #         color = "$foreground";
      #         font_size = 25;
      #         font_family = "JetBrainsMono NF Medium";
      #         position = "0, 20";
      #         halign = "center";
      #         valign = "center";
      #       }
      #       {
      #         monitor = "";
      #         text = "cmd[update:1000] echo \"$(~/.config/hypr/scripts/whatsong.sh)\"";
      #         color = "$foreground";
      #         font_size = 18;
      #         font_family = "JetBrainsMono NF ExtraBold, Font Awesome 6 Free Solid";
      #         position = "0, 40";
      #         halign = "center";
      #         valign = "bottom";
      #       }
      #     ];
      #
      #     "input-field" = [
      #       {
      #         monitor = "";
      #         size = "400, 60";
      #         outline_thickness = 2;
      #         dots_size = 0.2;
      #         dots_spacing = 0.2;
      #         dots_center = true;
      #         outer_color = "rgba(0, 0, 0, 0)";
      #         inner_color = "rgba(0, 0, 0, 0.5)";
      #         font_color = "rgb(200, 200, 200)";
      #         fade_on_empty = false;
      #         font_family = "JetBrainsMono NF Italic";
      #         placeholder_text = "<i><span foreground=\"##cdd6f4\">Input Password...</span></i>";
      #         hide_input = false;
      #         position = "0, -40";
      #         halign = "center";
      #         valign = "center";
      #       }
      #     ];
      #
      #     auth = {
      #       fingerprint = {
      #         enabled = true;
      #       };
      #     };
      #   };
      # };

      # services.hyprpaper = {
      #   enable = true;
      #   settings = {
      #     ipc = "on";
      #     splash = false;
      #     wallpaper = [
      #       ",~/Pictures/wallpapers/desktop-wallpaper"
      #     ];
      #   };
      # };

      # screenshot annotator
      programs.swappy = {
        enable = true;
        settings = {
          "Config" = {
            save_dir = "$HOME/Pictures/Screenshots";
            save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
          };
        };
      };

      xdg.configFile = {
        "hypr/noctalia".source =
          config.lib.file.mkOutOfStoreSymlink "${dotfiles_path}/modules/hyprland/noctalia";
      };
    };
}
