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
        enable = true;

        settings.windowrule = [
          "idle_inhibit fullscreen, match:class .* title:.*"
          "suppress_event maximize, match:class .*"
          # override opacity for some apps
          "opacity 1.0 override 1.0 override, match:title (.*)(YouTube)(.*)$"
          "opacity 1.0 override 1.0 override, match:title (.*)(Twitch)(.*)$"
          "opacity 1.0 override 1.0 override, match:title (.*)(Prime Video)(.*)$"
          "opacity 1.0 override 1.0 override, match:title (.*)([Mm]onkeytype)(.*)$"
          "opacity 1.0 override 1.0 override, match:class (.*)(GoodNotes|Goodnotes)(.*)$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(obsidian)(.)*$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(gwenview)$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(okular)$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(zathura)$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(vlc)$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(mpv)$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(Typora)$"
          "opacity 1.0 override 1.0 override, match:class ^(.)*(YACReader)$"
          "opacity 1.0 override 1.0 override, float on, match:title ^(Picture-in-Picture)$"
          "opacity 1.0 override 1.0 override, match:class nl.jknaapen.fladder"
          "opacity 1.0 override 1.0 override, match:title rmpc"
          # special class which should be floating
          "float on, match:class com.github.finefindus.eyedropper"
          "float on, match:class com.network.manager"

          # change the border color due to floating and pinned windows
          "border_color rgb(FF0000) rgb(880808), match:float 1"
          "border_color rgb(FF0000) rgb(ef8113), match:pin 1"

        ];

        extraConfig = ''
          windowrule {
            name = "waypaper"
            match:class = (.*)waypaper(.*)
            float = on
            size = 900 500
            center = on
          }

          windowrule {
            name = "dialogs"
            match:title = (.*)(Open File|Save As|Open Folder)(.*)
            center = on
            float = on
          }

          windowrule {
            name = "Pop-Up Terminal"
            match:class = (.*)floating(.*)
            float = on
            center = on
            size = 900 500
          }

          windowrule {
            name = "Steam Games"
            match:class = steam_app_(.*)
            fullscreen = true
            opacity = 1.0
          }

          windowrule {
            name = "Floatui Fallback"
            match:class = floatui-.*
            tag = +floatui
            size = 800 460
          }

          windowrule {
            name = "Floatui Notes"
            match:class = floatui-notes
            tag = +floatui
            size = 900 900
          }

          windowrule {
            name = "Floatui Bluetooth"
            match:class = floatui-bluetooth
            tag = +floatui
            size = 800 600
          }

          windowrule {
            name = "Floatui Audio Mixer"
            match:class = floatui-audio
            tag = +floatui
            size = 600 450
          }

          windowrule {
            name = "Floatui Timer"
            match:class = floatui-timer
            tag = +floatui
            size = 600 300
          }

          windowrule {
            name = "Floatui Mastodon"
            match:class = floatui-mastodon
            tag = +floatui
            size = 800 480
          }

          windowrule {
            name = "Floatui Matrix"
            match:class = floatui-matrix
            tag = +floatui
            size = 800 480
          }

          windowrule {
            name = "Floatui Memo"
            match:class = floatui-memo
            tag = +floatui
            size = 800 480
          }

          windowrule {
            name = "Floatui Files"
            match:class = floatui-files
            tag = +floatui
            size = 800 480
          }

          windowrule {
            name = "Floatui Wifi"
            match:class = floatui-wifi
            tag = +floatui
            size = 800 680
          }

          windowrule {
            name = "Floatui"
            match:tag = floatui
            float = on
            center = on
          }
        '';
      };
    };
}
