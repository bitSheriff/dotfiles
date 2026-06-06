hl.config({
    input = {
        kb_layout = "de",
        kb_options = "caps:escape",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },
    cursor = {
        hide_on_key_press = true,
    },
    general = {
        gaps_in = 5,
        gaps_out = 5,
        border_size = 2,
        col = {
            active_border = { colors = { "rgb(cfc985)", "rgb(14130f)" }, angle = 90 },
            nogroup_border = "rgba(282a36dd)",
            nogroup_border_active = { colors = { "rgb(bd93f9)", "rgb(44475a)" }, angle = 90 },
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true,
    },
    decoration = {
        rounding = 10,
        active_opacity = 0.95,
        inactive_opacity = 0.9,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
    group = {
        groupbar = {
            enabled = true,
            font_size = 12,
            gradients = true,
            height = 18,
            priority = 3,
            render_titles = true,
            scrolling = true,
            round_only_edges = false,
            rounding_power = 3.0,
            gradient_rounding = 5,
            gaps_in = 1,
            gaps_out = 1,
        },
    },
    misc = {
        font_family = "Comic Mono",
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.device({ name = "zsa-technology-labs-voyager", kb_layout = "us", kb_variant = "intl", kb_options = "compose:ralt" })