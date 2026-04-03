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
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/hypr";
    "mpv/script-opts/modernz.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mpv/script-opts/modernz.conf";
    "mpv/scripts".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/mpv/scripts";
    "noctalia".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/noctalia";
    "nvim-vanilla".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/nvim-vanilla";
    "opencode".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/opencode";
    "quickshell".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/quickshell";
    "qutebrowser".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/qutebrowser";
    "wofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/wofi";
    "zathura/zathurarc".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/zathura/zathurarc";
  };
  home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.ssh";
  home.file.".local/lib".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/../lib";
  home.file.".config/1Password/ssh/agent.toml".text = ''
    [[ssh-keys]]
    vault = "bitSheriff"
  '';

  home.sessionVariables = {
    # Default Programs
    TERMINAL = "kitty";
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "firefox";
    MANPAGER = "'nvim +Man!'";

    # Directories
    BIN_PATH = "$HOME/.local/bin";
    LIB_PATH = "$HOME/.local/lib";
    DOTFILES_DIR = "$HOME/code/dotfiles"; # define the folder where the dotfiles are located
    CACHE_DIR = "$HOME/.cache"; # define the folder for temporary cache files
    CODE_DIR = "$HOME/code"; # define the folder for the most coding projects
    WALLPAPER_DIR = "$HOME/Pictures/wallpapers"; # define the folder for the wallpapers

    # use 1Password as the SSH Agent
    SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

    # path where different age keys are stored
    AGE_KEY_DIR = "$HOME/.age";

    ADW_DISABLE_PORTAL = "1"; # Force libadwaita to use dark mode
    GTK_THEME = "Adwaita:dark"; # Fallback for some GTK apps

  };

  # PATH
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.config/hypr/scripts"
    "/var/lib/flatpak/exports/share/applications"
    "/usr/bin"
  ];

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
