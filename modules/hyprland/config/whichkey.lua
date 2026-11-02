-- WhichKey-style HUD: shows the active submap's keybinds as a Noctalia
-- notification. See scripts/whichkey.nix for the rendering side.
hl.on("keybinds.submap", function(name)
    local safe = (name or ""):gsub("[^%w_%-]", "")
    os.execute("whichkey-hud '" .. safe .. "' >/dev/null 2>&1 &")
end)
