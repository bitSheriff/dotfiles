{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
        programs.kitty = {
          enable = true;

          # Font configuration
          font = {
            name = "Comic Mono";
            size = 11;
          };

          settings = {
            # Font Variants
            bold_font = "auto";
            italic_font = "auto";
            bold_italic_font = "auto";
            disable_ligatures = "never";

            # Cursor
            cursor_shape = "block";
            cursor_beam_thickness = "1.5";
            cursor_underline_thickness = "2.0";
            cursor_blink_interval = -1;

            # Scrollback
            scrollback_lines = 2000;
            wheel_scroll_multiplier = "5.0";
            touch_scroll_multiplier = "1.0";

            # Mouse
            mouse_hide_wait = "3.0";
            url_style = "curly";
            detect_urls = "yes";
            copy_on_select = "no";
            pointer_shape_when_grabbed = "arrow";
            default_pointer_shape = "beam";

            # Performance
            repaint_delay = 10;
            input_delay = 3;
            sync_to_monitor = "yes";

            # Bell
            enable_audio_bell = "no";
            window_alert_on_bell = "yes";
            bell_on_tab = "🔔 ";

            # Window Layout
            remember_window_size = "yes";
            initial_window_width = 640;
            initial_window_height = 400;
            window_border_width = "0.5pt";
            draw_minimal_borders = "yes";
            placement_strategy = "center";
            inactive_text_alpha = "1.0";
            confirm_os_window_close = 0;

            # Tab Bar
            tab_bar_edge = "bottom";
            tab_bar_style = "fade";
            tab_bar_min_tabs = 2;
            tab_switch_strategy = "previous";
            tab_separator = " ┇";
            active_tab_font_style = "bold-italic";
            inactive_tab_font_style = "normal";
            tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}";

            # Advanced
            shell = ".";
            editor = "nvim";
            allow_remote_control = "yes";
            listen_on = "none";
            update_check_interval = 24;
            clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";
            allow_hyperlinks = "yes";
            shell_integration = "enabled";
            term = "xterm-kitty";

            # Background
            dynamic_background_opacity = "yes";
          };

          # Keybindings
          keybindings = {
            # The 'kitty_mod' defaults to ctrl+shift
            "kitty_mod+c" = "copy_to_clipboard";
            "kitty_mod+v" = "paste_from_clipboard";
            "kitty_mod+s" = "paste_from_selection";

            # Window Management
            "kitty_mod+enter" = "new_window";
            "kitty_mod+]" = "next_window";
            "kitty_mod+[" = "previous_window";
            "kitty_mod+f" = "move_window_forward";
            "kitty_mod+b" = "move_window_backward";

            # Custom Window Resizing
            "ctrl+left" = "resize_window narrower";
            "ctrl+right" = "resize_window wider";
            "ctrl+up" = "resize_window taller";
            "ctrl+down" = "resize_window shorter";

            # Custom Window Movement
            "shift+up" = "move_window up";
            "shift+left" = "move_window left";
            "shift+right" = "move_window right";
            "shift+down" = "move_window down";

            # Tab Management
            "kitty_mod+right" = "next_tab";
            "kitty_mod+left" = "previous_tab";
            "kitty_mod+t" = "new_tab_with_cwd .";
            "kitty_mod+q" = "close_tab";

            # Opacity shortcuts
            "kitty_mod+a>m" = "set_background_opacity +0.1";
            "kitty_mod+a>l" = "set_background_opacity -0.1";
            "kitty_mod+a>1" = "set_background_opacity 1";
            "kitty_mod+a>d" = "set_background_opacity default";
          };

          # Theme integration
          # Since you had 'include wallust.conf' and 'include current-theme.conf',
          # you can append extra raw config here.
          extraConfig = ''
            include themes/noctalia.conf
          '';
        };
      };
}
