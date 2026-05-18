{
  config,
  pkgs,
  lib,
  inputs,
  activeUsers,
  ...
}:

{
  # System-level user declaration - only if benjamin is in activeUsers
  users.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-benjamin.path;
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

  # System Wide Secrets
  sops = {
    defaultSopsFile = ../encrypted/secrets.yaml;
    secrets = {
      # User password
      user-benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
        key = "hosts/${config.networking.hostName}/benjamin";
        neededForUsers = true;
      };

      "nix_cache_priv" = {
        key = "nix/cache/rhodos/priv";
      };

      # root needs this ssh key to update the nix store from known devices (like a private nix cache)
      root_ssh_key = {
        key = "ssh/root/priv";
        path = "/root/.ssh/id_ed25519";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

  };

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) (
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
        inputs.agenix.homeManagerModules.default
        inputs.sops-nix.homeManagerModules.sops
      ];

      programs.home-manager.enable = true;
      home = {

        username = "benjamin";
        homeDirectory = "/home/benjamin";
        stateVersion = "25.11";
        file.".local/lib".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/../lib";

        sessionVariables = {
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
        sessionPath = [
          "$HOME/.local/bin"
          "$HOME/.cargo/bin"
          "$HOME/.config/hypr/scripts"
          "/var/lib/flatpak/exports/share/applications"
          "/usr/bin"
        ];

        pointerCursor = {
          gtk.enable = true;
          x11.enable = true;
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 24;
        };

        activation.report-changes = config.lib.dag.entryAnywhere ''
          ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
        '';

      };

      xdg = {
        enable = true;
        mime = {
          enable = true;
        };
        mimeApps = {
          enable = true;

          defaultApplications = {
            # get desktop file names: ls /run/current-system/sw/share/applications/ | grep X

            # Office Stuff
            "application/pdf" = [ "org.pwmt.zathura.desktop" ];
            # Media
            "image/png" = [ "com.interversehq.qView.desktop" ];
            "image/jpeg" = [ "com.interversehq.qView.desktop" ];
            "image/webp" = [ "com.interversehq.qView.desktop" ];
            "video/mp4" = [ "mpv.desktop" ];
            # Web
            "x-scheme-handler/https" = [ "firefox.desktop" ];
            # Archives
            "application/zip" = [ "peazip.desktop" ];
            "application/x-zip-compressed" = [ "peazip.desktop" ];
            "application/x-tar" = [ "peazip.desktop" ]; # .tar
            "application/gzip" = [ "peazip.desktop" ]; # .tar.gz / .tgz
            "application/x-gzip" = [ "peazip.desktop" ];
            "application/bzip2" = [ "peazip.desktop" ]; # .tar.bz2
            "application/x-bzip2" = [ "peazip.desktop" ];
            "application/x-xz" = [ "peazip.desktop" ]; # .tar.xz
            "application/x-zstd" = [ "peazip.desktop" ]; # .tar.zst
            "application/x-7z-compressed" = [ "peazip.desktop" ]; # .7z
            "application/x-rar" = [ "peazip.desktop" ]; # .rar
            "application/x-rar-compressed" = [ "peazip.desktop" ];
          };
        };
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

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };

      ##### SOPS #####
      home.packages = [ pkgs.sops ];
      age.identityPaths = [ "~/.age" ];

      sops = {
        defaultSopsFile = ../encrypted/secrets.yaml;
        age.keyFile = "${config.home.homeDirectory}/.age/dotfiles.key";

        secrets = {
          profile_picture = {
            sopsFile = ../encrypted/.face.enc;
            format = "binary";
            path = "${config.home.homeDirectory}/.face";
          };

          qutebrowser_urls = {
            sopsFile = ../encrypted/qutebrowser_urls.txt;
            format = "binary";
            path = "${config.home.homeDirectory}/.config/qutebrowser/bookmarks/urls";
          };

          # SSH Stuff
          ssh_hosts = {
            sopsFile = ../encrypted/ssh_hosts.txt;
            format = "binary";
            path = "${config.home.homeDirectory}/.ssh/hosts";
          };

          ssh_key_general = {
            key = "ssh/general/priv";
            path = "${config.home.homeDirectory}/.ssh/id_ed25519";
          };
          ssh_key_general_pub = {
            key = "ssh/general/pub";
            path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
          };

          # API Keys and Access Tokens
          "api/openai" = {
            key = "api_keys/openai";
          };

          "access/github" = {
            key = "access_token/github";
          };

        };
      };

      # load the data from the files into environment variables
      programs.zsh.initContent = ''
        export GITHUB_TOKEN="$(cat ${config.sops.secrets."access/github".path})"
      '';

    }
  );
}
