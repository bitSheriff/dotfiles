{ config, pkgs, lib, ... }:

let
  dotfiles = "/home/benjamin/code/dotfiles/configuration";
in
{
  # This replaces the automated loop with explicit links
  # It works exactly like 'stow configuration'
  xdg.configFile = {
    "1Password/ssh/agent.toml".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/1Password/ssh/agent.toml";
    "clang".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/clang";
    "direnv".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/direnv";
    "fuzzel".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/fuzzel";
    "hypr".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/hypr";
    "kitty".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/kitty";
    "lazygit".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/lazygit";
    "mise".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mise";
    "mpd".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mpd";
    "mpv".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mpv";
    "noctalia".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/noctalia";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/nvim";
    "nvim-vanilla".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/nvim-vanilla";
    "opencode".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/opencode";
    "qt5ct".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/qt5ct";
    "qt6ct".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/qt6ct";
    "quickshell".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/quickshell";
    "qutebrowser".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/qutebrowser";
    "shell".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/shell";
    "swappy".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/swappy";
    "television".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/television";
    "theming".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/theming";
    "wofi".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/wofi";
    "starship.toml".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/starship.toml";
    "yazi".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/yazi";
    "zed".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/zed";
    "zellij".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/zellij";
    "zathura/zathurarc".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/zathura/zathurarc";
    "gromit-mpx.cfg".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/gromit-mpx.cfg";
  };

  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.zshrc";
  home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.gitconfig";
  home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.ssh";
  home.file.".local/share/bin".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.bin";

  home.username = "benjamin";
  home.homeDirectory = "/home/benjamin";
  home.stateVersion = "25.11";

  xdg.enable = true;

  home.pointerCursor = {
      gtk.enable = true;
      # x11.enable = true; # Enable if you use any XWayland apps
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style.name = "adwaita-dark";
    };

    gtk = {
      gtk4.theme = null;
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
      };
    };

  programs.home-manager.enable = true;
}
