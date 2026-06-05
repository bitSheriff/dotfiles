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
      wayland.windowManager.hyprland = {
        settings = {
          # source = [
          #   ''
          #     colors = require("noctalia.noctalia-colors")
          #   ''
          # ];

          # curve = [
          #   { name = "wind"; type = "bezier"; points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ]; }
          #   { name = "winIn"; type = "bezier"; points = [ [ 0.1 1.1 ] [ 0.1 1.1 ] ]; }
          #   { name = "winOut"; type = "bezier"; points = [ [ 0.3 (-0.3) ] [ 0 1 ] ]; }
          #   { name = "liner"; type = "bezier"; points = [ [ 1 1 ] [ 1 1 ] ]; }
          # ];

          # animation = [
          #   {
          #     leaf = "windows";
          #     enabled = true;
          #     speed = 6;
          #     type = "bezier";
          #     style = "slide";
          #   }
          #   {
          #     leaf = "windowsIn";
          #     enabled = true;
          #     speed = 6;
          #     # bezier = "winIn";
          #     style = "slide";
          #   }
          #   {
          #     leaf = "windowsOut";
          #     enabled = true;
          #     speed = 5;
          #     # bezier = "winOut";
          #     style = "slide";
          #   }
          #   {
          #     leaf = "windowsMove";
          #     enabled = true;
          #     speed = 5;
          #     # bezier = "wind";
          #     style = "slide";
          #   }
          #   {
          #     leaf = "border";
          #     enabled = true;
          #     speed = 1;
          #     bezier = "liner";
          #   }
          #   {
          #     leaf = "borderangle";
          #     enabled = true;
          #     speed = 30;
          #     bezier = "liner";
          #     style = "loop";
          #   }
          #   {
          #     leaf = "fade";
          #     enabled = true;
          #     speed = 10;
          #     bezier = "default";
          #   }
          #   {
          #     leaf = "workspaces";
          #     enabled = true;
          #     speed = 5;
          #     bezier = "wind";
          #   }
          # ];

          config = {
            general = {
              gaps_in = 5;
              gaps_out = 5;
              border_size = 2;
              col = {
                active_border = {
                  colors = [
                    "rgb(cfc985)"
                    "rgb(14130f)"
                    # (lua "colors.primary")
                    # (lua "colors.secondary")
                  ];
                  angle = 90;
                };
                # inactive_border = lua "colors.surface";
                nogroup_border = "rgba(282a36dd)";
                nogroup_border_active = {
                  colors = [
                    "rgb(bd93f9)"
                    "rgb(44475a)"
                  ];
                  angle = 90;
                };
              };
              resize_on_border = false;
              allow_tearing = false;
              layout = "dwindle";
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
                # color = lua "colors.tertiary";
              };

              blur = {
                enabled = true;
                size = 3;
                passes = 1;
                vibrancy = 0.1696;
              };
            };

            group = {
              col = {
                # border_active = lua "colors.secondary";
                # border_inactive = lua "colors.surface";
                # border_locked_active = lua "colors.error";
                # border_locked_inactive = lua "colors.surface";
              };

              groupbar = {
                enabled = true;
                font_size = 12;
                gradients = true;
                height = 18;
                priority = 3;
                render_titles = true;
                scrolling = true;
                col = {
                  # active = lua "colors.secondary";
                  # inactive = lua "colors.surface";
                  # locked_active = lua "colors.error";
                  # locked_inactive = lua "colors.surface";
                };
                round_only_edges = false;
                rounding_power = 3.0;
                gradient_rounding = 5;
                gaps_in = 1;
                gaps_out = 1;
              };
            };

            misc = {
              font_family = "Comic Mono";
              force_default_wallpaper = 0;
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
            };

            ecosystem = {
              no_update_news = true;
              no_donation_nag = true;
            };

            # plugin = {
            #   easymotion = {
            #     textsize = 20;
            #     textcolor = "rgba(ffffffff)";
            #     bgcolor = "rgba(000000ff)";
            #     textfont = "Sans";
            #     textpadding = "2 5 5 2";
            #     bordersize = 0;
            #     bordercolor = "rgba(ffffffff)";
            #     rounding = 0;
            #     motionkeys = "asdfghjklbgnh";
            #   };
            # };
          };

          workspace_rule = [
            {
              workspace = "special:term-scratchpad";
              on_created_empty = "kitty --class term-scratchpad";
            }
          ];
        };

      };

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
