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
  mainMod = "SUPER";

  terminal = "kitty";
  terminal2 = "ghostty";
  browser = "firefox";
  browser2 = "qutebrowser";
  fileManager = "nemo";
  fileManager2 = "kitty -e yazi $HOME";
  menu = "noctalia-shell ipc call launcher toggle";
  menu2 = "fuzzel";
  passwordmng = "1password";
  password2fa = "enteauth";
  wallpaper-tool = "waypaper";
  emojipicker = "BEMOJI_PICKER_CMD='wofi -d --hide-scroll --width=350 --location=center' bemoji -n -e | wl-copy";
  emojipicker2 = "jome | wl-copy";
  unicodepicker = "(FZF_DEFAULT_OPTS='' unipicker --copy-command wl-copy --command 'wofi -d') | wl-copy";
  flameshot = "XDG_CURRENT_DESKTOP=sway flameshot gui";
  hyprswitchgui = "hyprswitch gui --mod-key super_l --key tab --max-switch-offset 9";
  clipboard = "noctalia-shell ipc call plugin:clipboard toggle";
  code = "zeditor";
  calc = "speedcrunch";
  obsidian = "obsidian";
  todomng = "todoist";
  calendar = "korganizer";
  focuswriter = "typora";
  quicktodo = "floatui todo";
  quickmemo = "floatui memo";
  pdfreader = "zathura";
  pdfreader2 = "okular";
  matrixclient = "cinny";
  spotify = "spotify-launcher";
  podcast = "pocket-casts-desktop";
  musicplayer = "kitty -e kew";
  mpv = "mpv --idle --force-window";

  dsp = {
    exec = cmd: lua "hl.dsp.exec_cmd([[${cmd}]])";
    close = lua "hl.dsp.window.close()";
    kill = lua "hl.dsp.window.kill()";
    focus = dir: lua "hl.dsp.focus({ direction = '${dir}' })";
    move = dir: lua "hl.dsp.window.move({ direction = '${dir}' })";
    workspace = ws: lua "hl.dsp.focus({ workspace = ${toString ws} })";
    moveToWorkspaceSilent = ws: lua "hl.dsp.window.move({ workspace = ${toString ws}, silent = true })";
    toggleSpecial = name: lua "hl.dsp.workspace.toggle_special('${name}')";
    moveToSpecial = name: lua "hl.dsp.window.move({ workspace = 'special:${name}' })";
    float = lua "hl.dsp.window.float({ action = 'toggle' })";
    pin = lua "hl.dsp.window.pin()";
    fullscreen = lua "hl.dsp.window.fullscreen({ action = 'toggle' })";
    resize =
      x: y: lua "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })";
    submap = name: lua "hl.dsp.submap('${name}')";
  };

  bind = keys: dispatcher: {
    _args = [
      keys
      dispatcher
    ];
  };
  binde = keys: dispatcher: {
    _args = [
      keys
      dispatcher
    ];
    repeating = true;
  };
  bindm = keys: dispatcher: {
    _args = [
      keys
      dispatcher
    ];
    mouse = true;
  };
in
{
  home-manager.users.benjamin =
    { config, lib, ... }:
    lib.mkIf (lib.elem "benjamin" activeUsers) {
      wayland.windowManager.hyprland.settings = {
        unbind = [ "CTRL, D" ];

        # binde = [
        #   (binde "XF86AudioRaiseVolume" (dsp.exec "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"))
        #   (binde "XF86AudioLowerVolume" (dsp.exec "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"))
        #   (binde "XF86MonBrightnessUp" (dsp.exec "brightnessctl set +5%"))
        #   (binde "XF86MonBrightnessDown" (dsp.exec "brightnessctl set 5%-"))
        #   (binde "ALT + XF86MonBrightnessUp" (dsp.exec "hyprctl hyprsunset temperature +500"))
        #   (binde "ALT + XF86MonBrightnessDown" (dsp.exec "hyprctl hyprsunset temperature -500"))
        #   (binde "${mainMod} + CTRL + left" (dsp.resize (-20) 0))
        #   (binde "${mainMod} + CTRL + right" (dsp.resize 20 0))
        #   (binde "${mainMod} + CTRL + up" (dsp.resize 0 (-20)))
        #   (binde "${mainMod} + CTRL + down" (dsp.resize 0 20))
        #   (binde "${mainMod} + CTRL + H" (dsp.resize (-20) 0))
        #   (binde "${mainMod} + CTRL + L" (dsp.resize 20 0))
        #   (binde "${mainMod} + CTRL + K" (dsp.resize 0 (-20)))
        #   (binde "${mainMod} + CTRL + J" (dsp.resize 0 20))
        # ];

        bind = [
          (bind "SHIFT + XF86AudioRaiseVolume" (dsp.exec "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 10%+"))
          (bind "SHIFT + XF86AudioLowerVolume" (dsp.exec "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 10%-"))
          (bind "XF86AudioMute" (dsp.exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
          (bind "${mainMod} + XF86AudioMute" (dsp.exec "noctalia-shell ipc call volume openPanel"))
          (bind "XF86AudioPlay" (dsp.exec "playerctl play-pause"))
          (bind "XF86AudioPause" (dsp.exec "playerctl play-pause"))
          (bind "XF86AudioNext" (dsp.exec "playerctl next"))
          (bind "XF86AudioPrev" (dsp.exec "playerctl previous"))
          (bind "${mainMod} + R" (dsp.exec "~/.local/bin/wm-reload"))
          (bind "${mainMod} + SHIFT + Q" dsp.close)
          (bind "XF86AudioMedia" (dsp.exec "noctalia-shell ipc call controlCenter toggle"))
          (bind "SHIFT + XF86AudioMedia" (dsp.exec "noctalia-shell ipc call sessionMenu toggle"))
          (bind "${mainMod} + D" (dsp.exec menu))
          (bind "${mainMod} + SHIFT + D" (dsp.exec menu2))
          (bind "Print" (dsp.exec "hyprshot -m region --clipboard-only --freeze"))
          (bind "${mainMod} + Print" (dsp.exec "grim -g \"$(slurp)\" - | swappy -f -"))
          (bind "${mainMod} + PERIOD" (dsp.exec emojipicker))
          (bind "${mainMod} + SHIFT + PERIOD" (dsp.exec emojipicker2))
          (bind "${mainMod} + CTRL + PERIOD" (dsp.exec unicodepicker))
          (bind "${mainMod} + CTRL + E" (dsp.exec "hyprpicker -a"))
          (bind "${mainMod} + V" (dsp.exec clipboard))
          (bind "${mainMod} + SHIFT + V" (
            dsp.exec "cliphist list | wofi --dmenu | cliphist decode | wl-copy"
          ))
          (bind "${mainMod} + ALT + W" (dsp.exec wallpaper-tool))
          (bind "${mainMod} + SHIFT + A" (dsp.exec quickmemo))
          (bind "${mainMod} + XF86AudioMedia" (dsp.exec quickmemo))
          (bind "${mainMod} + escape" (dsp.exec "~/.config/hypr/scripts/quick_settings.py"))
          (bind "${mainMod} + B" (dsp.exec browser))
          (bind "${mainMod} + CTRL + B" (dsp.exec "${browser} --private-window"))
          (bind "${mainMod} + SHIFT + B" (dsp.exec browser2))
          (bind "${mainMod} + RETURN" (dsp.exec terminal))
          (bind "${mainMod} + SHIFT + RETURN" (dsp.exec terminal2))
          (bind "${mainMod} + E" (dsp.exec fileManager))
          (bind "${mainMod} + SHIFT + E" (dsp.exec fileManager2))
          (bind "${mainMod} + O" (dsp.exec obsidian))
          (bind "${mainMod} + C" (dsp.exec code))
          (bind "${mainMod} + SHIFT + C" (dsp.exec calc))
          (bind "${mainMod} + M" (dsp.exec passwordmng))
          (bind "${mainMod} + SHIFT + M" (dsp.exec password2fa))
          (bind "${mainMod} + T" (dsp.exec todomng))
          (bind "${mainMod} + SHIFT + T" (dsp.exec quicktodo))
          (bind "${mainMod} + CTRL + T" (dsp.exec calendar))
          (bind "${mainMod} + CTRL + Z" (dsp.exec focuswriter))
          (bind "${mainMod} + SHIFT + Z" (dsp.exec pdfreader))
          (bind "${mainMod} + XF86AudioPlay" (dsp.exec spotify))
          (bind "${mainMod} + SHIFT + XF86AudioPlay" (dsp.exec musicplayer))
          (bind "${mainMod} + CTRL + XF86AudioPlay" (dsp.exec mpv))

          (bind "${mainMod} + left" (dsp.focus "l"))
          (bind "${mainMod} + right" (dsp.focus "r"))
          (bind "${mainMod} + up" (dsp.focus "u"))
          (bind "${mainMod} + down" (dsp.focus "d"))
          (bind "${mainMod} + SHIFT + left" (dsp.move "l"))
          (bind "${mainMod} + SHIFT + right" (dsp.move "r"))
          (bind "${mainMod} + SHIFT + up" (dsp.move "u"))
          (bind "${mainMod} + SHIFT + down" (dsp.move "d"))
          (bind "${mainMod} + H" (dsp.focus "l"))
          (bind "${mainMod} + L" (dsp.focus "r"))
          (bind "${mainMod} + K" (dsp.focus "u"))
          (bind "${mainMod} + J" (dsp.focus "d"))
          (bind "${mainMod} + SHIFT + H" (dsp.move "l"))
          (bind "${mainMod} + SHIFT + L" (dsp.move "r"))
          (bind "${mainMod} + SHIFT + K" (dsp.move "u"))
          (bind "${mainMod} + SHIFT + J" (dsp.move "d"))

          (bind "${mainMod} + F" dsp.float)
          (bind "${mainMod} + SHIFT + F" dsp.pin)
          (bind "${mainMod} + CTRL + F" dsp.fullscreen)
          (bind "${mainMod} + ALT + F" (dsp.exec "killall -SIGUSR1 waybar"))
          (bind "${mainMod} + CTRL + W" (dsp.exec "~/.config/hypr/scripts/zen-mode.sh"))

          (bind "${mainMod} + S" (dsp.toggleSpecial "magic"))
          (bind "${mainMod} + SHIFT + S" (dsp.moveToSpecial "magic"))
          (bind "${mainMod} + CTRL + S" (dsp.toggleSpecial "magic2"))
          (bind "${mainMod} + CTRL + SHIFT + S" (dsp.moveToSpecial "magic2"))
          (bind "${mainMod} + ALT + right" (lua "hl.dsp.focus({ workspace = 'e+1' })"))
          (bind "${mainMod} + ALT + left" (lua "hl.dsp.focus({ workspace = 'e-1' })"))
          (bind "${mainMod} + ALT + L" (lua "hl.dsp.focus({ workspace = 'e+1' })"))
          (bind "${mainMod} + ALT + H" (lua "hl.dsp.focus({ workspace = 'e-1' })"))
          (bind "${mainMod} + CTRL + TAB" (
            dsp.exec "noctalia-shell ipc call plugin:workspace-overview toggle"
          ))
          (bind "${mainMod} + TAB" (lua "hl.dsp.focus({ workspace = 'e+1' })"))
          (bind "${mainMod} + SHIFT + TAB" (lua "hl.dsp.focus({ workspace = 'e-1' })"))
          (bind "${mainMod} + ALT + RETURN" (dsp.toggleSpecial "term-scratchpad"))

          (bind "${mainMod} + N" (dsp.submap "note"))
          (bind "${mainMod} + SHIFT + N" (dsp.toggleSpecial "note"))
          (bind "${mainMod} + SHIFT + G" (dsp.submap "group"))
          (bind "${mainMod} + SHIFT + R" (dsp.submap "resize"))
          (bind "${mainMod} + SHIFT + Print" (dsp.submap "screen"))
          (bind "${mainMod} + CTRL + E" (dsp.submap "files"))
          (bind "${mainMod} + CTRL + C" (dsp.submap "code"))
          (bind "${mainMod} + CTRL + D" (dsp.submap "apps"))
        ]
        ++ (map (i: (bind "${mainMod} + ${toString i}" (dsp.workspace i))) (lib.range 1 9))
        ++ [ (bind "${mainMod} + 0" (dsp.workspace 10)) ]
        ++ (map (i: (bind "${mainMod} + F${toString (i - 10)}" (dsp.workspace i))) (lib.range 11 19))
        ++ (map (i: (bind "${mainMod} + SHIFT + ${toString i}" (dsp.moveToWorkspaceSilent i))) (
          lib.range 1 9
        ))
        ++ [ (bind "${mainMod} + SHIFT + 0" (dsp.moveToWorkspaceSilent 10)) ]
        ++ (map (i: (bind "${mainMod} + SHIFT + F${toString (i - 10)}" (dsp.moveToWorkspaceSilent i))) (
          lib.range 11 19
        ));

        # Mouse Binds
        # bindm = [
        #   (bindm "${mainMod}, mouse:272" (lua "hl.dsp.window.drag()"))
        #   (bindm "${mainMod}, mouse:273" (lua "hl.dsp.window.resize()"))
        # ];

        # extraConfig = ''
        #   hl.define_submap("note", function()
        #       hl.bind("S", hl.dsp.workspace.toggle_special("note"))
        #       hl.bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:note" }))
        #       hl.bind("V", hl.dsp.exec_cmd("~/.local/bin/inbox.sh -c"))
        #       hl.bind("M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${quickmemo}]])) end)
        #       hl.bind("I", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox]])) end)
        #       hl.bind("SHIFT + I", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox -n]])) end)
        #       hl.bind("L", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox -l]])) end)
        #       hl.bind("O", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${obsidian}]])) end)
        #       hl.bind("D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty nvim ~/notes/Journal/Entries/Daily/$(date +"%F").md]])) end)
        #       hl.bind("T", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty --class floating --title "Pop-up Terminal" -e ~/.local/bin/todo]])) end)
        #       hl.bind("${mainMod} + N", hl.dsp.submap("reset"))
        #       hl.bind("escape", hl.dsp.submap("reset"))
        #   end)
        #
        #   hl.define_submap("group", function()
        #       hl.bind("G", hl.dsp.group.toggle())
        #       hl.bind("SHIFT + G", hl.dsp.group.lock({ action = "toggle" }))
        #       hl.bind("ALT + U", hl.dsp.group.move_window({ direction = "out" }))
        #       hl.bind("ALT + H", hl.dsp.group.move_window({ direction = "left" }))
        #       hl.bind("ALT + L", hl.dsp.group.move_window({ direction = "right" }))
        #       hl.bind("ALT + K", hl.dsp.group.move_window({ direction = "up" }))
        #       hl.bind("ALT + J", hl.dsp.group.move_window({ direction = "down" }))
        #       hl.bind("H", hl.dsp.group.prev())
        #       hl.bind("L", hl.dsp.group.next())
        #       hl.bind("K", hl.dsp.group.focus_prev())
        #       hl.bind("J", hl.dsp.group.focus_next())
        #       hl.bind("left", hl.dsp.group.prev())
        #       hl.bind("right", hl.dsp.group.next())
        #       hl.bind("escape", hl.dsp.submap("reset"))
        #       hl.bind("return", hl.dsp.submap("reset"))
        #   end)
        #
        #   hl.define_submap("resize", function()
        #       hl.bind("right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
        #       hl.bind("left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
        #       hl.bind("down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
        #       hl.bind("up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
        #       hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
        #       hl.bind("SHIFT + left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
        #       hl.bind("SHIFT + down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
        #       hl.bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
        #       hl.bind("escape", hl.dsp.submap("reset"))
        #       hl.bind("return", hl.dsp.submap("reset"))
        #       hl.bind("${mainMod} + R", hl.dsp.submap("reset"))
        #   end)
        #
        #   hl.define_submap("screen", function()
        #       hl.bind("a", hl.dsp.exec_cmd("hyprshot -m region --freeze"))
        #       hl.bind("w", hl.dsp.exec_cmd("hyprshot -m window --freeze"))
        #       hl.bind("m", hl.dsp.exec_cmd("hyprshot -m output --freeze"))
        #       hl.bind("escape", hl.dsp.submap("reset"))
        #       hl.bind("return", hl.dsp.submap("reset"))
        #       hl.bind("${mainMod} + R", hl.dsp.submap("reset"))
        #   end)
        #
        #   hl.define_submap("files", function()
        #       hl.bind("D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${fileManager} ~/Downloads/]])) end)
        #       hl.bind("M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${fileManager} ~/Music/]])) end)
        #       hl.bind("V", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${fileManager} ~/Videos/]])) end)
        #       hl.bind("P", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${fileManager} ~/Pictures/]])) end)
        #       hl.bind("W", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${fileManager} ~/Documents/]])) end)
        #       hl.bind("C", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${fileManager} ~/code/]])) end)
        #       hl.bind("escape", hl.dsp.submap("reset"))
        #   end)
        #
        #   hl.define_submap("code", function()
        #       hl.bind("D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${code} ~/code/dotfiles/]])) end)
        #       hl.bind("B", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${code} ~/code/blog/]])) end)
        #       hl.bind("C", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${code} ~/code/]])) end)
        #       hl.bind("SHIFT + D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty -e nvim ~/code/dotfiles/]])) end)
        #       hl.bind("SHIFT + B", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty -e nvim ~/code/blog/]])) end)
        #       hl.bind("SHIFT + C", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[kitty -e nvim ~/code/]])) end)
        #       hl.bind("escape", hl.dsp.submap("reset"))
        #   end)
        #
        #   hl.define_submap("apps", function()
        #       hl.bind("M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${mpv}]])) end)
        #       hl.bind("SHIFT + M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${matrixclient}]])) end)
        #       hl.bind("S", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${spotify}]])) end)
        #       hl.bind("SHIFT + S", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[signal-desktop]])) end)
        #       hl.bind("P", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[${pdfreader}]])) end)
        #       hl.bind("escape", hl.dsp.submap("reset"))
        #   end)
        # '';
      };
    };
}
