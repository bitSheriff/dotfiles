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
        window_rule = [
          {
            match = {
              class = "^(kitty)$";
            };
            opacity = "0.95 0.9";
          }
          {
            match = {
              class = "^(floating)$";
            };
            float = true;
            size = "700 450";
            center = true;
          }
          {
            match = {
              class = "^(swappy)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(waypaper)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(org.gnome.Calculator)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(speedcrunch)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(imv)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(pavucontrol)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(blueman-manager)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(nm-connection-editor)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(org.kde.polkit-kde-authentication-agent-1)$";
            };
            float = true;
          }
          {
            match = {
              title = "^(Pop-up Terminal)$";
            };
            float = true;
            size = "1000 650";
            center = true;
          }

          {
            match = {
              class = ".*";
            };
            suppress_event = "maximize";
          }
          {
            match = {
              class = "^(term-scratchpad)$";
            };
            workspace = "special:term-scratchpad";
            size = "1200 800";
            center = true;
          }

          {
            match = {
              class = "^(quick-settings)$";
            };
            float = true;
            size = "500 700";
            move = "100%-520 50";
            pin = true;
          }

          {
            match = {
              class = "^(noctalia-shell)$";
              title = "^(launcher)$";
            };
            float = true;
            size = "100% 100%";
            move = "0 0";
            pin = true;
            no_anim = true;
          }

          {
            match = {
              class = "^(cinny)$";
            };
            float = true;
            workspace = "9";
          }

          {
            match = {
              class = "^(spotify-launcher)$";
            };
            workspace = "10";
          }
          {
            match = {
              class = "^(pocket-casts-desktop)$";
            };
            workspace = "10";
          }
          {
            match = {
              title = "^(kew)$";
            };
            workspace = "10";
          }

          {
            match = {
              class = "^(com.github.th_ch.youtube_music)$";
            };
            float = true;
            workspace = "10";
            size = "1200 800";
            center = true;
          }

          {
            match = {
              class = "^(obsidian)$";
            };
            float = true;
            size = "1400 900";
            center = true;
          }
          {
            match = {
              class = "^(todoist)$";
            };
            float = true;
            size = "1000 800";
            center = true;
          }
          {
            match = {
              class = "^(korganizer)$";
            };
            float = true;
            size = "1200 800";
            center = true;
          }
          {
            match = {
              class = "^(typora)$";
            };
            float = true;
            size = "1200 900";
            center = true;
          }
          {
            match = {
              class = "^(org.pwmt.zathura)$";
            };
            float = true;
            size = "1000 1200";
            center = true;
          }
          {
            match = {
              class = "^(okular)$";
            };
            float = true;
            size = "1000 1200";
            center = true;
          }
          {
            match = {
              class = "^(enteauth)$";
            };
            float = true;
            size = "400 700";
            center = true;
          }
          {
            match = {
              class = "^(1Password)$";
            };
            float = true;
            size = "1000 700";
            center = true;
          }

          {
            match = {
              title = "^(floating)$";
            };
            float = true;
            size = "1000 700";
            center = true;
          }

          {
            match = {
              class = "^(obsidian)$";
            };
            workspace = "special:note";
          }
          {
            match = {
              class = "^(typora)$";
            };
            workspace = "special:note";
          }
          {
            match = {
              class = "^(todoist)$";
            };
            workspace = "special:note";
          }
          {
            match = {
              class = "^(korganizer)$";
            };
            workspace = "special:note";
          }
        ];

        # layer_rule = [
        #   { match = { namespace = "noctalia-shell"; }; no_anim = true; blur = true; ignore_zero = true; }
        # ];
      };
    };
}
