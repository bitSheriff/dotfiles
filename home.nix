{ config, pkgs, lib, ... }:

let
  # The ABSOLUTE path as a string (keep the quotes!)
  dotfiles = "/home/benjamin/code/dotfiles/configuration";
in
{
  # This replaces the automated loop with explicit links
  # It works exactly like 'stow configuration'
  xdg.configFile = {
    "noctalia".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/noctalia";
    "fuzzel".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/fuzzel";
    "kitty".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/kitty";
    "hypr".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/hypr";
    "shell".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/shell";
    "zed".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/zed";
    "yazi".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/yazi";
    "qutebrowser".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/qutebrowser";
    "opencode".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/opencode";
    "hledger".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/hledger";
    "1Password/ssh/agent.toml".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/1Password/ssh/agent.toml";
    "starship.toml".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/starship.toml";
  };
  home.file.".local/share/applications".source = config.lib.file.mkOutOfStoreSymlink "/run/current-system/sw/share/applications";
  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.zshrc";
  home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.gitconfig";
  home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.ssh";

  home.username = "benjamin";
  home.homeDirectory = "/home/benjamin";
  home.stateVersion = "25.11";

  xdg.enable = true;
  xdg.systemDirs.data = [
    "${pkgs.papirus-icon-theme}/share"
    "/run/current-system/sw/share"
    "/home/benjamin/.nix-profile/share"
  ];

  home.pointerCursor = {
      gtk.enable = true;
      # x11.enable = true; # Enable if you use any XWayland apps
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
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
