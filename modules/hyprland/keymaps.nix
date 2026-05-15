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
          "$mainMod" = "SUPER";

          # Programs from programs.conf
          "$terminal" = "kitty";
          "$terminal2" = "ghostty";
          "$browser" = "firefox";
          "$browser2" = "qutebrowser";
          "$fileManager" = "nemo";
          "$fileManager2" = "kitty -e yazi $HOME";
          "$menu" = "noctalia-shell ipc call launcher toggle";
          "$menu2" = "fuzzel";
          "$passwordmng" = "1password";
          "$password2fa" = "enteauth";
          "$wallpaper-tool" = "waypaper";
          "$emojipicker" =
            "BEMOJI_PICKER_CMD='wofi -d --hide-scroll --width=350 --location=center' bemoji -n -e | wl-copy";
          "$emojipicker2" = "jome | wl-copy";
          "$unicodepicker" =
            "(FZF_DEFAULT_OPTS='' unipicker --copy-command wl-copy --command 'wofi -d') | wl-copy";
          "$flameshot" = "XDG_CURRENT_DESKTOP=sway flameshot gui";
          "$hyprswitchgui" = "hyprswitch gui --mod-key super_l --key tab --max-switch-offset 9";
          "$clipboard" = "noctalia-shell ipc call plugin:clipboard toggle";
          "$code" = "zeditor";
          "$calc" = "speedcrunch";
          "$obsidian" = "obsidian";
          "$todomng" = "todoist";
          "$calendar" = "korganizer";
          "$focuswriter" = "typora";
          "$quicktodo" = "floatui todo";
          "$quickmemo" = "floatui memo";
          "$pdfreader" = "zathura";
          "$pdfreader2" = "okular";
          "$matrixclient" = "cinny";
          "$spotify" = "spotify-launcher";
          "$podcast" = "pocket-casts-desktop";
          "$musicplayer" = "kitty -e kew";
          "$mpv" = "mpv --idle --force-window";

          unbind = [
            "CTRL, D"
          ];

          binde = [
            ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"
            ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
            "ALT, XF86MonBrightnessUp, exec, hyprctl hyprsunset temperature +500"
            "ALT, XF86MonBrightnessDown, exec, hyprctl hyprsunset temperature -500"
            "SUPER CTRL, left, resizeactive, -20 0"
            "SUPER CTRL, right, resizeactive, 20 0"
            "SUPER CTRL, up, resizeactive, 0 -20"
            "SUPER CTRL, down, resizeactive, 0 20"
            "SUPER CTRL, H, resizeactive, -20 0"
            "SUPER CTRL, L, resizeactive, 20 0"
            "SUPER CTRL, K, resizeactive, 0 -20"
            "SUPER CTRL, J, resizeactive, 0 20"
          ];

          bind = [
            "SHIFT, XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 10%+"
            "SHIFT, XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 10%-"
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            "$mainMod, XF86AudioMute, exec, noctalia-shell ipc call volume openPanel"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPrev, exec, playerctl previous"
            "$mainMod, R, exec, ~/.local/bin/wm-reload"
            "$mainMod SHIFT, Q, killactive,"
            ", XF86AudioMedia, exec, noctalia-shell ipc call controlCenter toggle"
            "SHIFT, XF86AudioMedia, exec, noctalia-shell ipc call sessionMenu toggle"
            "$mainMod, D, exec, $menu"
            "$mainMod SHIFT, D, exec, $menu2"
            ", Print, exec, hyprshot -m region --clipboard-only --freeze"
            "$mainMod, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
            "$mainMod, PERIOD, exec, $emojipicker"
            "$mainMod SHIFT, PERIOD, exec, $emojipicker2"
            "$mainMod CTRL, PERIOD, exec, $unicodepicker"
            "$mainMod CTRL, E, exec, hyprpicker -a"
            "$mainMod, V, exec, $clipboard"
            "$mainMod SHIFT, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
            "$mainMod ALT, W, exec, $wallpaper-tool"
            "$mainMod SHIFT, A, exec, $quickmemo"
            "$mainMod, XF86AudioMedia, exec, $quickmemo"
            "$mainMod, escape, exec, ~/.config/hypr/scripts/quick_settings.py"
            "$mainMod, B, exec, $browser"
            "$mainMod CTRL, B, exec, $browser --private-window"
            "$mainMod SHIFT, B, exec, $browser2"
            "$mainMod, RETURN, exec, $terminal"
            "$mainMod SHIFT, RETURN, exec, $terminal2"
            "$mainMod, E, exec, $fileManager"
            "$mainMod SHIFT, E, exec, $fileManager2"
            "$mainMod, O, exec, $obsidian"
            "$mainMod, C, exec, $code"
            "$mainMod SHIFT, C, exec, $calc"
            "$mainMod, M, exec, $passwordmng"
            "$mainMod SHIFT, M, exec, $password2fa"
            "$mainMod, T, exec, $todomng"
            "$mainMod SHIFT, T, exec, $quicktodo"
            "$mainMod CTRL, T, exec, $calendar"
            "$mainMod CTRL, Z, exec, $focuswriter"
            "$mainMod SHIFT, Z, exec, $pdfreader"
            "$mainMod, XF86AudioPlay, exec, $spotify"
            "$mainMod SHIFT, XF86AudioPlay, exec, $musicplayer"
            "$mainMod CTRL, XF86AudioPlay, exec, $mpv"

            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"
            "$mainMod SHIFT, left, movewindow, l"
            "$mainMod SHIFT, right, movewindow, r"
            "$mainMod SHIFT, up, movewindow, u"
            "$mainMod SHIFT, down, movewindow, d"
            "$mainMod, H, movefocus, l"
            "$mainMod, L, movefocus, r"
            "$mainMod, K, movefocus, u"
            "$mainMod, J, movefocus, d"
            "$mainMod SHIFT, H, movewindow, l"
            "$mainMod SHIFT, L, movewindow, r"
            "$mainMod SHIFT, K, movewindow, u"
            "$mainMod SHIFT, J, movewindow, d"

            "$mainMod, F, togglefloating"
            "$mainMod SHIFT, F, pin"
            "$mainMod CTRL, F, fullscreen"
            "$mainMod ALT, F, exec, killall -SIGUSR1 waybar"
            "$mainMod SHIFT, W, togglesplit"
            "$mainMod CTRL, W, exec, ~/.config/hypr/scripts/zen-mode.sh"

            "$mainMod, 1, workspace, 1"
            "$mainMod, 2, workspace, 2"
            "$mainMod, 3, workspace, 3"
            "$mainMod, 4, workspace, 4"
            "$mainMod, 5, workspace, 5"
            "$mainMod, 6, workspace, 6"
            "$mainMod, 7, workspace, 7"
            "$mainMod, 8, workspace, 8"
            "$mainMod, 9, workspace, 9"
            "$mainMod, 0, workspace, 10"
            "$mainMod, F1, workspace, 11"
            "$mainMod, F2, workspace, 12"
            "$mainMod, F3, workspace, 13"
            "$mainMod, F4, workspace, 14"
            "$mainMod, F5, workspace, 15"
            "$mainMod, F6, workspace, 16"
            "$mainMod, F7, workspace, 17"
            "$mainMod, F8, workspace, 18"
            "$mainMod, F9, workspace, 19"

            "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
            "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
            "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
            "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
            "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
            "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
            "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
            "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
            "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
            "$mainMod SHIFT, 0, movetoworkspacesilent, 10"
            "$mainMod SHIFT, F1, movetoworkspacesilent, 11"
            "$mainMod SHIFT, F2, movetoworkspacesilent, 12"
            "$mainMod SHIFT, F3, movetoworkspacesilent, 13"
            "$mainMod SHIFT, F4, movetoworkspacesilent, 14"
            "$mainMod SHIFT, F5, movetoworkspacesilent, 15"
            "$mainMod SHIFT, F6, movetoworkspacesilent, 16"
            "$mainMod SHIFT, F7, movetoworkspacesilent, 17"
            "$mainMod SHIFT, F8, movetoworkspacesilent, 18"
            "$mainMod SHIFT, F9, movetoworkspacesilent, 19"

            "$mainMod, S, togglespecialworkspace, magic"
            "$mainMod SHIFT, S, movetoworkspace, special:magic"
            "$mainMod CTRL, S, togglespecialworkspace, magic2"
            "$mainMod CTRL SHIFT, S, movetoworkspace, special:magic2"
            "$mainMod ALT, right, workspace, e+1"
            "$mainMod ALT, left, workspace, e-1"
            "$mainMod ALT, L, workspace, e+1"
            "$mainMod ALT, H, workspace, e-1"
            "$mainMod CTRL, TAB, exec, noctalia-shell ipc call plugin:workspace-overview toggle"
            "$mainMod, TAB, workspace, e+1"
            "$mainMod SHIFT, TAB, workspace, e-1"
            "SUPER ALT, RETURN, togglespecialworkspace, term-scratchpad"

            # Submap triggers
            "$mainMod, N, submap, note"
            "$mainMod SHIFT, N, togglespecialworkspace, note"
            "$mainMod SHIFT, G, submap, group"
            "$mainMod SHIFT, R, submap, resize"
            "$mainMod SHIFT, Print, submap, screen"
            "$mainMod CTRL, E, submap, files"
            "$mainMod CTRL, C, submap, code"
            "$mainMod CTRL, D, submap, apps"
          ];

          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];
        };

        extraConfig = ''

          submap = note
              bind = , S, togglespecialworkspace, note
              bind = SHIFT, S, movetoworkspace, special:note
              bind = , V, exec, ~/.local/bin/inbox.sh -c
              bind = , M, exec, hyprctl dispatch submap reset; $quickmemo
              bind = , I, exec, hyprctl dispatch submap reset; kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox
              bind = SHIFT, I, exec, hyprctl dispatch submap reset; kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox -n
              bind = , L, exec, hyprctl dispatch submap reset; kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox -l
              bind = , O, exec, hyprctl dispatch submap reset; $obsidian
              bind = , D, exec, hyprctl dispatch submap reset; kitty nvim ~/notes/Journal/Entries/Daily/$(date +"%F").md
              bind = , T, exec, hyprctl dispatch submap reset; kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/todo
              bind = $mainMod, N, submap, reset
              bind = , escape, submap, reset
          submap = reset

          submap = group
              bind = , G, togglegroup
              bind = SHIFT, G, lockactivegroup, toggle
              bind = ALT, U, moveoutofgroup,
              bind = ALT, H, moveintogroup, l
              bind = ALT, L, moveintogroup, r
              bind = ALT, K, moveintogroup, u
              bind = ALT, J, moveintogroup, d
              bind = , H, changegroupactive, b
              bind = , L, changegroupactive, f
              bind = , K, changegroupactive, u
              bind = , J, changegroupactive, d
              bind = , left, changegroupactive, b
              bind = , right, changegroupactive, f
              bind = , escape, submap, reset
              bind = , return, submap, reset
          submap = reset

          submap = resize
              binde = , right, resizeactive, 100 0
              binde = , left, resizeactive, -100 0
              binde = , down, resizeactive, 0 100
              binde = , up, resizeactive, 0 -100
              binde = SHIFT, right, resizeactive, 10 0
              binde = SHIFT, left, resizeactive, -10 0
              binde = SHIFT, down, resizeactive, 0 10
              binde = SHIFT, up, resizeactive, 0 -10
              bind = , escape, submap, reset
              bind = , return, submap, reset
              bind = $mainMod, R, submap, reset
          submap = reset

          submap = screen
              bind = , a, exec, hyprshot -m region --freeze
              bind = , w, exec, hyprshot -m window --freeze
              bind = , m, exec, hyprshot -m output --freeze
              bind = , escape, submap, reset
              bind = , return, submap, reset
              bind = $mainMod, R, submap, reset
          submap = reset

          submap = files
              bind = , D, exec, hyprctl dispatch submap reset; $fileManager ~/Downloads/
              bind = , M, exec, hyprctl dispatch submap reset; $fileManager ~/Music/
              bind = , V, exec, hyprctl dispatch submap reset; $fileManager ~/Videos/
              bind = , P, exec, hyprctl dispatch submap reset; $fileManager ~/Pictures/
              bind = , W, exec, hyprctl dispatch submap reset; $fileManager ~/Documents/
              bind = , C, exec, hyprctl dispatch submap reset; $fileManager ~/code/
              bind = , escape, submap, reset
          submap = reset

          submap = code
              bind = , D, exec, hyprctl dispatch submap reset; $code ~/code/dotfiles/
              bind = , B, exec, hyprctl dispatch submap reset; $code ~/code/blog/
              bind = , C, exec, hyprctl dispatch submap reset; $code ~/code/
              bind = SHIFT, D, exec, hyprctl dispatch submap reset; kitty -e nvim ~/code/dotfiles/
              bind = SHIFT, B, exec, hyprctl dispatch submap reset; kitty -e nvim ~/code/blog/
              bind = SHIFT, C, exec, hyprctl dispatch submap reset; kitty -e nvim ~/code/
              bind = , escape, submap, reset
          submap = reset

          submap = apps
              bind = , M, exec, hyprctl dispatch submap reset; $mpv
              bind = SHIFT, M, exec, hyprctl dispatch submap reset; $matrixclient
              bind = , S, exec, hyprctl dispatch submap reset; $spotify
              bind = SHIFT, S, exec, hyprctl dispatch submap reset; signal-desktop
              bind = , P, exec, hyprctl dispatch submap reset; $pdfreader
              bind = , escape, submap, reset
          submap = reset
        '';
      };
    };
}
