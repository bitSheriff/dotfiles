{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  dotfiles = "/home/benjamin/code/dotfiles/configuration";
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./modules/sops.nix
  ];

  home.username = "benjamin";
  home.homeDirectory = "/home/benjamin";
  home.stateVersion = "25.11";

  xdg.enable = true;
  xdg.configFile = {
    "fuzzel".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/fuzzel";
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/hypr";
    "kitty".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/kitty";
    "mpd".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mpd";
    "mpv/script-opts/modernz.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mpv/script-opts/modernz.conf";
    "mpv/scripts".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mpv/scripts";
    "noctalia".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/noctalia";
    "nvim-vanilla".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/nvim-vanilla";
    "opencode".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/opencode";
    "quickshell".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/quickshell";
    "qutebrowser".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/qutebrowser";
    "shell".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/shell";
    "theming".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/theming";
    "wofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/wofi";
    "starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/starship.toml";
    "zathura/zathurarc".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/zathura/zathurarc";
    "gromit-mpx.cfg".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/gromit-mpx.cfg";
  };
  home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.ssh";
  home.file.".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/../bin";
  home.file.".local/lib".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/../lib";
  home.file.".config/1Password/ssh/agent.toml".text = ''
    [[ssh-keys]]
    vault = "bitSheriff"
  '';

  home.sessionVariables = {
    ADW_DISABLE_PORTAL = "1"; # Force libadwaita to use dark mode
    GTK_THEME = "Adwaita:dark"; # Fallback for some GTK apps
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true; # for XWayland Apps
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  qt = {
    enable = true;
    platformTheme.name = "kde";
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
  systemd.user.startServices = "sd-switch"; # remove the Warning with NixOS 26.03

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    enableZshIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
