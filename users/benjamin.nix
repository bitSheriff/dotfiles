{
  config,
  pkgs,
  lib,
  inputs,
  sopsMod,
  activeUsers,
  ...
}:

{
  # System-level user declaration - only if benjamin is in activeUsers
  users.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    isNormalUser = true;
    home = "/home/benjamin";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "libvirtd"
      "dialout"
      "tty"
      "scanner"
      "lp"

    ];
  };

  # Home-manager configuration for benjamin - only if benjamin is in activeUsers
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) (
    {
      config,
      pkgs,
      lib,
      inputs,
      sopsMod,
      ...
    }:
    let
      dotfiles = "/home/benjamin/code/dotfiles/configuration";
    in
    {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
        sopsMod
      ];

      home.username = "benjamin";
      home.homeDirectory = "/home/benjamin";
      home.stateVersion = "25.11";

      xdg.enable = true;
      xdg.configFile = {
      };
      home.file.".local/lib".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/../lib";

      home.sessionVariables = {
        # Default Programs
        TERMINAL = "kitty";
        EDITOR = "nvim";
        VISUAL = "nvim";
        BROWSER = "firefox";
        MANPAGER = "nvim +Man!";

        # Directories
        BIN_PATH = "$HOME/.local/bin";
        LIB_PATH = "$HOME/.local/lib";
        DOTFILES_DIR = "$HOME/code/dotfiles";
        CACHE_DIR = "$HOME/.cache";
        CODE_DIR = "$HOME/code";
        WALLPAPER_DIR = "$HOME/Pictures/wallpapers";

        # use 1Password as the SSH Agent
        SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

        # path where different age keys are stored
        AGE_KEY_DIR = "$HOME/.age";

        ADW_DISABLE_PORTAL = "1";
        GTK_THEME = "Adwaita:dark";

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
        x11.enable = true;
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
      systemd.user.startServices = "sd-switch";

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
  );
}
