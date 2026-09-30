{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{

  environment.systemPackages = with pkgs; [
  ];

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.zathura = {
      enable = true;

      # Colors (default-bg/fg, statusbar-*, inputbar-*, notification-*,
      # highlight-*, completion-*, recolor-lightcolor/darkcolor) and font are
      # owned by Stylix (modules/stylix) - do not set them here, they
      # conflict.
      options = {
        adjust-open = "best-fit";
        selection-clipboard = "clipboard";
        guioptions = "none";

        recolor = "true";
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

        # F5 = Toggle Presentation Mode
      };

    };
  };

}
