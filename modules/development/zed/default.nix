{ config, pkgs, ... }:

{
  imports = [
    ./keymap.nix
    ./tasks.nix
  ];

  # System-wide dev tools
  environment.systemPackages = with pkgs; [
    zed-editor
    nixd
  ];

  home-manager.users.benjamin = {
    programs.zed-editor = {
      enable = true;
      extensions = [ ];
      userSettings = {

        # Most important settings
        vim_mode = true;
        relative_line_numbers = "enabled";
        soft_wrap = "editor_width";
        tab_size = 4;
        autosave.after_delay.milliseconds = 1000;
        multi_cursor_modifier = "alt";

        # UI Stuff
        ui_font_size = 16;
        ui_font_family = "JetBrainsMono Nerd Font";
        buffer_font_size = 16;
        buffer_font_family = "Comic Mono";
        sticky_scroll.enabled = true;

        # like rainbow bracets
        indent_guides = {
          enabled = true;
          coloring = "indent_aware";
        };

        tabs = {
          file_icons = true;
          git_status = true;
        };

        # set dark and light theme
        theme = {
          mode = "dark";
          light = "One Light";
          dark = "noctalia";
        };

        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        languages = {
          markdown = {
            format_on_save = "on";
            tab_size = 4;
          };

          rust = {
            formatter = "language_server";
            format_on_save = "on";
            tab_size = 4;
          };

          nix = {
            formatter = "language_server";
            format_on_save = "on";
            tab_size = 2;
          };

        };

      };
    };
  };

}
