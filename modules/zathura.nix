{ config, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    mpv
  ];

  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      programs.zathura = {
        enable = true;

        options = {

          adjust-open = "best-fit";
          selection-clipboard = "clipboard";
          guioptions = "none";
          font = "JetBrainsMono Nerd Font Mono 12";
          default-bg = "#000000";
          default-fg = "#F7F7F6";

          statusbar-fg = "#B0B0B0";
          statusbar-bg = "#202020";

          inputbar-bg = "#151515";
          inputbar-fg = "#FFFFFF";

          notification-error-bg = "#AC4142";
          notification-error-fg = "#151515";

          notification-warning-bg = "#AC4142";
          notification-warning-fg = "#151515";

          highlight-color = "#F4BF75";
          highlight-active-color = "#6A9FB5";

          completion-highlight-fg = "#151515";
          completion-highlight-bg = "#90A959";

          completion-bg = "#303030";
          completion-fg = "#E0E0E0";

          notification-bg = "#90A959";
          notification-fg = "#151515";

          recolor = "true";
          recolor-lightcolor = "#000000";
          recolor-darkcolor = "#E0E0E0";
          recolor-reverse-video = "true";
          recolor-keephue = "true";
        };

        mappings = {

          "<C-r>" = "recolor"; # toggle dark mode
          "r" = "reload";
          "<S-r>" = "rotate";
          "<C-n>" = "toggle_statusbar"; # toggle the statusbar on the bottum (title of document and page)

          "<Right>" = "scroll full-down"; # scroll whole page
          "<Left>" = "scroll full-up";

          "f" = "toggle_fullscreen";
          "[fullscreen] f" = "toggle_fullscreen"; # exit fullscreen
          "[fullscreen] <Up>" = "scroll half-up";
          "[fullscreen] <Down>" = "scroll half-down";
          "[fullscreen] j" = "scroll full-down";
          "[fullscreen] k" = "scroll full-up";
          "[fullscreen] <Right>" = "scroll full-down";
          "[fullscreen] <Left>" = "scroll full-up";
        };

      };

    };

}
