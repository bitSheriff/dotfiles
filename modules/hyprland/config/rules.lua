hl.window_rule({ match = { class = "^(floating)$" }, float = true, size = "700 450", center = true })
hl.window_rule({ match = { class = "^(swappy)$" }, float = true })
hl.window_rule({ match = { class = "^(waypaper)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, float = true })
hl.window_rule({ match = { class = "^(speedcrunch)$" }, float = true })
hl.window_rule({ match = { class = "^(imv)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { title = "^(Pop-up Terminal)$" }, float = true, size = "1000 650", center = true })

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ match = { class = "^(term-scratchpad)$" }, workspace = "special:term-scratchpad", size = "1200 800", center = true })
hl.window_rule({ match = { class = "^(quick-settings)$" }, float = true, size = "500 700", move = "100%-520 50", pin = true })
hl.window_rule({ match = { class = "^(noctalia-shell)$", title = "^(launcher)$" }, float = true, size = "100% 100%", move = "0 0", pin = true, no_anim = true })
hl.window_rule({ match = { title = "^(floating)$" }, float = true, size = "1000 700", center = true })
hl.window_rule({ match = { class = "^(floatui-).*$" }, float = true, size = "1000 700", center = true })
hl.workspace_rule({ workspace = "special:term-scratchpad", on_created_empty = "kitty --class term-scratchpad" })

-- Producitivity Tools
hl.window_rule({ match = { class = "org.pwmt.zathura" }, opacity = "1.0 override" })
hl.window_rule({ match = { class = "org.kde.okular" }, opacity = "1.0 override" })

-- Media
hl.window_rule({ match = { class = "mpv" }, opacity = "1.0 override" })

-- Opaque Window Titles in the Browser
local opaque_titles = {
    ".*YouTube.*",
    ".*Twitch.*",
    "Picture-in-Picture",
    ".*Jitsi Meet.*",
}

for _, title_pattern in ipairs(opaque_titles) do
    hl.window_rule({ match = { title = title_pattern }, opacity = "1.0 override" })
end
