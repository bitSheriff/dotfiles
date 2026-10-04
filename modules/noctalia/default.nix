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
  # Primary/internal monitor connector per host, used below for
  # wallpaper.monitors.* and lockscreen widget placement
  # (defaultMonitor.${hostname}). Add an entry whenever a new host needs a
  # monitor-pinned noctalia setting; find connector names with
  # `hyprctl monitors | grep Monitor`.
  defaultMonitor = {
    delos = "eDP-1"; # Framework 13 internal panel
  };
in
{

  imports = [
  ];

  environment.systemPackages = with pkgs; [
    # noctalia itself is installed by the home-manager module below
    # (programs.noctalia, pointed at pkgs.noctalia via `package`)

    # needed for some plugins / screenshot & clipboard helpers
    cliphist
    curl
    ffmpeg
    gifski
    grim
    imagemagick
    jq
    slurp
    tesseract
    translate-shell
    wl-clipboard
    wl-screenrec
    gpu-screen-recorder
    zbar
  ];

  home-manager.users.benjamin =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    let
      monitor = defaultMonitor.${osConfig.networking.hostName} or null;
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      config = lib.mkIf (lib.elem "benjamin" activeUsers) {
        programs.noctalia = {
          enable = true;
          package = pkgs.noctalia;

          settings = lib.mkMerge [
            # Shared, host-agnostic settings.
            {
              calendar.enabled = true;
              control_center.calendar.show_week_numbers = true;

              plugins = {
                enabled = [ "noctalia/timer" ];
              };

              widget = {
                timer = {
                  type = "noctalia/timer:bar";
                };
              };

              bar.default = {
                font_family = "Comic Neue";
                font_scale = 1.2;
                font_weight = 700;
                padding = 14;
                thickness = 32;
                background_opacity = 0.1;

                # Widgets
                start = [
                  "clock"
                  "launcher"
                  "wallpaper"
                  "media"
                  "timer"
                ];
                center = [
                  "workspaces"
                ];
                end = [
                  "tray"
                  "notifications"
                  "clipboard"
                  "network"
                  "bluetooth"
                  "volume"
                  "brightness"
                  "battery"
                  "control-center"
                  "session"
                ];

              };

              dock = {
                enabled = true;
                icon_size = 32;
                reserve_space = false;
                smart_auto_hide = true;
              };

              lockscreen_widgets = {
                enabled = false;
                schema_version = 2;
                grid = {
                  cell_size = 16;
                  major_interval = 4;
                  visible = true;
                };
              };

              shell = {
                polkit_agent = true;
                screen_time_enabled = true;
              };

              wallpaper = {
                # path where the Selector searches for images
                directory = "/home/benjamin/Pictures/wallpapers/desktop";
              };

            }

            (lib.mkIf (monitor != null) {
              # wallpaper = {
              #   default.path = lib.mkForce "/home/benjamin/Pictures/wallpapers/desktop/classics/Claude.Monet-Cliff.Walk.at.Purville(1882).jpg";
              #   last.path = "/home/benjamin/Pictures/wallpapers/desktop/classics/Claude.Monet-Cliff.Walk.at.Purville(1882).jpg";
              #   monitors.${monitor}.path =
              #     "/home/benjamin/Pictures/wallpapers/desktop/classics/Claude.Monet-Cliff.Walk.at.Purville(1882).jpg";
              # };

              lockscreen_widgets = {
                widget_order = [ "lockscreen-login-box@${monitor}" ];
                widget."lockscreen-login-box@${monitor}" = {
                  box_height = 196.0;
                  box_width = 810.0;
                  cx = 1128.0;
                  cy = 1322.0;
                  output = monitor;
                  placement_height = 1504.0;
                  placement_width = 2256.0;
                  rotation = 0.0;
                  type = "login_box";
                  settings = {
                    background_color = "surface_variant";
                    background_opacity = 0.88;
                    background_radius = 12.0;
                    center_password_text = false;
                    input_opacity = 1.0;
                    input_radius = 6.0;
                    layout = "regular";
                    show_caps_lock = true;
                    show_keyboard_layout = true;
                    show_login_button = true;
                    show_media = true;
                    show_session_buttons = true;
                    show_unlock_hint = true;
                    show_weather = true;
                  };
                };
              };
            })
          ];
        };
      };
    };

}
