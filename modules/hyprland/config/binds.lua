hl.define_submap("note", function()
    hl.bind("S", hl.dsp.workspace.toggle_special("note"), { description = "Toggle note scratchpad" })
    hl.bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:note" }), { description = "Move window to note scratchpad" })
    hl.bind("V", hl.dsp.exec_cmd("~/.local/bin/inbox.sh -c"), { description = "Capture clipboard to inbox" })
    hl.bind("M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[floatui memo]])) end, { description = "Open memo" })
    hl.bind("I", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox]])) end, { description = "Open inbox" })
    hl.bind("SHIFT + I", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox -n]])) end, { description = "Open inbox (new entry)" })
    hl.bind("L", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ --class floating --title "Pop-up Terminal" -e ~/.local/bin/inbox -l]])) end, { description = "Open inbox (list)" })
    hl.bind("O", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[obsidian]])) end, { description = "Open Obsidian" })
    hl.bind("D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ nvim ~/notes/Journal/Entries/Daily/$(date +"%F").md]])) end, { description = "Open today's daily note" })
    hl.bind("T", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ --class floating --title "Pop-up Terminal" -e ~/.local/bin/todo]])) end, { description = "Open todo" })
    hl.bind("SUPER + N", hl.dsp.submap("reset"), { description = "Close menu" })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "Toggle group" })
hl.bind("SUPER + SHIFT + G", hl.dsp.group.lock({ action = "toggle" }), { description = "Toggle group lock" })
hl.define_submap("group", function()
    hl.bind("G", hl.dsp.group.toggle(), { description = "Toggle group" })
    hl.bind("SHIFT + G", hl.dsp.group.lock({ action = "toggle" }), { description = "Toggle group lock" })
    hl.bind("ALT + U", hl.dsp.group.move_window({ direction = "out" }), { description = "Move window out of group" })
    hl.bind("ALT + H", hl.dsp.group.move_window({ direction = "left" }), { description = "Move window in group left" })
    hl.bind("ALT + L", hl.dsp.group.move_window({ direction = "right" }), { description = "Move window in group right" })
    hl.bind("ALT + K", hl.dsp.group.move_window({ direction = "up" }), { description = "Move window in group up" })
    hl.bind("ALT + J", hl.dsp.group.move_window({ direction = "down" }), { description = "Move window in group down" })
    hl.bind("H", hl.dsp.group.prev(), { description = "Previous window in group" })
    hl.bind("L", hl.dsp.group.next(), { description = "Next window in group" })
    hl.bind("left", hl.dsp.group.prev(), { description = "Previous window in group" })
    hl.bind("right", hl.dsp.group.next(), { description = "Next window in group" })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true, description = "Grow width" })
    hl.bind("left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true, description = "Shrink width" })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true, description = "Grow height" })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true, description = "Shrink height" })
    hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true, description = "Grow width (fine)" })
    hl.bind("SHIFT + left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true, description = "Shrink width (fine)" })
    hl.bind("SHIFT + down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true, description = "Grow height (fine)" })
    hl.bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true, description = "Shrink height (fine)" })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("SUPER + R", hl.dsp.submap("reset"))
end)

hl.define_submap("screen", function()
    hl.bind("a", hl.dsp.exec_cmd(apps.screenshot .. " -m region --freeze"), { description = "Screenshot region" })
    hl.bind("w", hl.dsp.exec_cmd(apps.screenshot .. " -m window --freeze"), { description = "Screenshot window" })
    hl.bind("m", hl.dsp.exec_cmd(apps.screenshot .. " -m output --freeze"), { description = "Screenshot monitor" })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("SUPER + R", hl.dsp.submap("reset"))
end)

hl.define_submap("files", function()
    hl.bind("D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.file_manager .. [[ ~/Downloads/]])) end, { description = "Open Downloads" })
    hl.bind("M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.file_manager .. [[ ~/Music/]])) end, { description = "Open Music" })
    hl.bind("V", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.file_manager .. [[ ~/Videos/]])) end, { description = "Open Videos" })
    hl.bind("P", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.file_manager .. [[ ~/Pictures/]])) end, { description = "Open Pictures" })
    hl.bind("W", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.file_manager .. [[ ~/Documents/]])) end, { description = "Open Documents" })
    hl.bind("C", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.file_manager .. [[ ~/code/]])) end, { description = "Open code folder" })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.define_submap("code", function()
    hl.bind("D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.code_editor .. [[ ~/code/dotfiles/]])) end, { description = "Open dotfiles in editor" })
    hl.bind("B", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.code_editor .. [[ ~/code/blog/]])) end, { description = "Open blog in editor" })
    hl.bind("C", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.code_editor .. [[ ~/code/]])) end, { description = "Open code folder in editor" })
    hl.bind("SHIFT + D", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ -e nvim ~/code/dotfiles/]])) end, { description = "Open dotfiles in nvim" })
    hl.bind("SHIFT + B", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ -e nvim ~/code/blog/]])) end, { description = "Open blog in nvim" })
    hl.bind("SHIFT + C", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd(apps.terminal .. [[ -e nvim ~/code/]])) end, { description = "Open code folder in nvim" })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.define_submap("apps", function()
    hl.bind("M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[mpv --idle --force-window]])) end, { description = "Open mpv" })
    hl.bind("SHIFT + M", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[cinny]])) end, { description = "Open Cinny" })
    hl.bind("S", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[spotify-launcher]])) end, { description = "Open Spotify" })
    hl.bind("SHIFT + S", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[signal-desktop]])) end, { description = "Open Signal" })
    hl.bind("P", function() hl.dispatch(hl.dsp.submap("reset")); hl.dispatch(hl.dsp.exec_cmd([[zathura]])) end, { description = "Open Zathura" })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- SUPER + ? opens a searchable palette of the exec-backed binds below.
-- hyprctl binds -j can't tell us *what* a Lua bind runs (just an opaque
-- function ref), so wk_exec_bind() records {key, cmd, desc} itself, as the
-- single source of truth, into $XDG_RUNTIME_DIR/whichkey-exec.json for
-- scripts/whichkey-search.nix to read and run directly - no replaying
-- keypresses, no reflecting into the Lua VM from outside.
local WK_EXEC = {}

local function wk_exec_bind(keys, cmd, desc, opts)
    opts = opts or {}
    opts.description = desc
    hl.bind(keys, hl.dsp.exec_cmd(cmd), opts)
    WK_EXEC[#WK_EXEC + 1] = { key = keys, cmd = cmd, desc = desc }
end

local function wk_dump_exec()
    local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
    local f = io.open(runtime_dir .. "/whichkey-exec.json", "w")
    if not f then return end
    local function esc(s) return (s:gsub('[\\"]', '\\%0')) end
    local parts = {}
    for _, item in ipairs(WK_EXEC) do
        parts[#parts + 1] = string.format('{"key":"%s","cmd":"%s","desc":"%s"}', esc(item.key), esc(item.cmd), esc(item.desc))
    end
    f:write("[" .. table.concat(parts, ",") .. "]")
    f:close()
end

hl.unbind("CTRL, D")

hl.bind("SUPER + SHIFT + space", hl.dsp.exec_cmd("whichkey-search"), { description = "Search keybinds" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true, description = "Volume down" })
hl.bind("SHIFT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 10%+"), { repeating = true, locked = true, description = "Volume up (coarse)" })
hl.bind("SHIFT + XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 10%-"), { repeating = true, locked = true, description = "Volume down (coarse)" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, description = "Toggle mute" })
hl.bind("SUPER + XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-osd"), { locked = true, description = "Show volume OSD" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause media" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause media" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true, description = "Brightness down" })
hl.bind("SHIFT + XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"), { repeating = true, locked = true, description = "Brightness up (coarse)" })
hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { repeating = true, locked = true, description = "Brightness down (coarse)" })
wk_exec_bind("SUPER + R", "koreader", "Open KOReader")
hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close(), { description = "Close window" })
wk_exec_bind("XF86AudioMedia", "noctalia msg panel-toggle control-center", "Toggle control center")
wk_exec_bind("SHIFT + XF86AudioMedia", "noctalia msg panel-toggle session", "Toggle session menu")
wk_exec_bind("SUPER + D", "noctalia msg panel-toggle launcher", "Toggle launcher")
wk_exec_bind("SUPER + SHIFT + W", "noctalia msg panel-toggle wallpaper", "Toggle wallpaper picker")
wk_exec_bind("SUPER + SHIFT + D", apps.launcher, "Open app launcher")
wk_exec_bind("Print", apps.screenshot .. " -m region --clipboard-only --freeze", "Screenshot region to clipboard")
wk_exec_bind("SUPER + Print", "gradia --screenshot", "Open Gradia screenshot")
wk_exec_bind("SUPER + CTRL + TAB", "noctalia msg window-switcher ", "Window switcher") -- Window Switcher

wk_exec_bind("SUPER + period", apps.emoji_picker, "Emoji picker") -- command centralized in cfg.apps.emojiPicker (cfg.nix)
wk_exec_bind("SUPER + CTRL + period", "(FZF_DEFAULT_OPTS='' unipicker --copy-command wl-copy --command '" .. apps.menu .. "') | wl-copy", "Unicode picker")
wk_exec_bind("SUPER + CTRL + E", "hyprpicker -a", "Pick color from screen")
wk_exec_bind("SUPER + V", "noctalia msg panel-toggle clipboard", "Toggle clipboard history") -- clipboard is built into v5, no plugin needed
wk_exec_bind("SUPER + SHIFT + V", "cliphist list | " .. apps.menu .. " | cliphist decode | wl-copy", "Search clipboard history")
wk_exec_bind("SUPER + ALT + W", "waypaper", "Open Waypaper")
wk_exec_bind("SUPER + A", "floatui memo", "Open memo")
wk_exec_bind("SUPER + SHIFT+ A", "floatui todo", "Open todo")
wk_exec_bind("SUPER + XF86AudioMedia", "floatui memo", "Open memo")
wk_exec_bind("SUPER + B", apps.browser, "Open browser")
wk_exec_bind("SUPER + CTRL + B", "firefox --private-window", "Open Firefox private window") -- deliberately firefox-specific, not tied to apps.browser
wk_exec_bind("SUPER + SHIFT + B", "qutebrowser", "Open qutebrowser") -- deliberate alt browser
wk_exec_bind("SUPER + Return", apps.terminal, "Open terminal")
wk_exec_bind("SUPER + E", apps.file_manager, "Open file manager")
wk_exec_bind("SUPER + SHIFT + E", apps.terminal .. " -e yazi $HOME", "Open yazi")
wk_exec_bind("SUPER + O", "obsidian", "Open Obsidian")
wk_exec_bind("SUPER + C", apps.code_editor, "Open code editor")
wk_exec_bind("SUPER + SHIFT + C", "speedcrunch", "Open calculator")
wk_exec_bind("SUPER + ALT + C", apps.markdown_editor, "Open markdown editor")
wk_exec_bind("SUPER + M", "1password", "Open 1Password")
wk_exec_bind("SUPER + SHIFT + M", "floatui pass", "Open password picker")
wk_exec_bind("SUPER + T", "todoist", "Open Todoist")
wk_exec_bind("SUPER + SHIFT + T", "floatui todo", "Open todo")
wk_exec_bind("SUPER + CTRL + T", "korganizer", "Open KOrganizer")
wk_exec_bind("SUPER + CTRL + Z", "marktext", "Open MarkText")
wk_exec_bind("SUPER + SHIFT + Z", "zathura", "Open Zathura")
wk_exec_bind("SUPER + XF86AudioPlay", "spotify-launcher", "Open Spotify")
wk_exec_bind("SUPER + SHIFT + XF86AudioPlay", apps.terminal .. " -e kew", "Open kew")
wk_exec_bind("SUPER + CTRL + XF86AudioPlay", "mpv --idle --force-window", "Open mpv")

hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "Shrink width" })
hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true, description = "Grow width" })
hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "Shrink height" })
hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "Grow height" })
hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })

hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.pin(), { description = "Pin window" })
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ action = "toggle" }), { description = "Toggle fullscreen" })
wk_exec_bind("SUPER + ALT + F", "killall -SIGUSR1 waybar", "Reload waybar")
wk_exec_bind("SUPER + Z", "zen-mode", "Toggle zen mode")
hl.bind("SUPER + W", hl.dsp.layout("togglesplit"), { description = "Toggle split layout" })

hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle magic scratchpad" })
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move window to magic scratchpad" })
hl.bind("SUPER + CTRL + S", hl.dsp.workspace.toggle_special("magic2"), { description = "Toggle magic2 scratchpad" })
hl.bind("SUPER + CTRL + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic2" }), { description = "Move window to magic2 scratchpad" })
hl.bind("SUPER + ALT + right", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind("SUPER + ALT + left", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind("SUPER + ALT + L", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind("SUPER + ALT + H", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
-- TODO: the v4 workspace-overview plugin has no v5 equivalent for Hyprland
-- yet (overview is a Niri/Umbriel-native compositor feature in v5). Needs
-- a replacement plugin or a different binding once one exists.
-- hl.bind("SUPER + CTRL + Tab", hl.dsp.exec_cmd("noctalia msg plugin ..."))
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind("SUPER + ALT + Return", hl.dsp.workspace.toggle_special("term-scratchpad"), { description = "Toggle dropdown terminal" })
hl.bind("SUPER + SHIFT + Return", hl.dsp.workspace.toggle_special("term-scratchpad"), { description = "Toggle dropdown terminal" }) -- v4 dropdown terminal muscle memory

hl.bind("SUPER + N", hl.dsp.submap("note"), { description = "+Note menu" })
hl.bind("SUPER + SHIFT + N", hl.dsp.workspace.toggle_special("note"), { description = "Toggle note scratchpad" })
hl.bind("SUPER + SHIFT + ALT + G", hl.dsp.submap("group"), { description = "+Group menu" })
hl.bind("SUPER + SHIFT + R", hl.dsp.submap("resize"), { description = "+Resize menu" })
hl.bind("SUPER + SHIFT + Print", hl.dsp.submap("screen"), { description = "+Screenshot menu" })
hl.bind("SUPER + CTRL + E", hl.dsp.submap("files"), { description = "+Files menu" })
hl.bind("SUPER + CTRL + C", hl.dsp.submap("code"), { description = "+Code menu" })
hl.bind("SUPER + CTRL + D", hl.dsp.submap("apps"), { description = "+Apps menu" })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 9 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }), { description = "Focus workspace " .. i })
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }), { description = "Move window to workspace " .. i })
end
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 10 }), { description = "Focus workspace 10" })
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = false }), { description = "Move window to workspace 10" })

for i = 11, 19 do
    hl.bind("SUPER + F" .. (i - 10), hl.dsp.focus({ workspace = i }), { description = "Focus workspace " .. i })
    hl.bind("SUPER + SHIFT + F" .. (i - 10), hl.dsp.window.move({ workspace = i, follow = false }), { description = "Move window to workspace " .. i })
end

wk_dump_exec()
