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

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) (
    let
      envCfg = config.cfg.env;
    in
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
        # Stylix's home-manager module is auto-imported by its NixOS module
        # (stylix.homeManagerIntegration.autoImport, default true) via
        # home-manager.sharedModules - importing it again here duplicates it
        # and breaks on stylix's read-only options (e.g. stylix.base16).
      ];

      programs.home-manager.enable = true;
      home = {

        username = "benjamin";
        homeDirectory = "/home/benjamin";
        stateVersion = "25.11";
        file.".local/lib".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/../lib";

        sessionVariables = {
          # Default Programs (from cfg.env, see cfg.nix)
          EDITOR = envCfg.editor;
          VISUAL = envCfg.editor;
          TERMINAL = envCfg.terminal;
          BROWSER = envCfg.browser;
          PAGER = envCfg.pager;
          MANPAGER = "nvim +Man!";
          EDITOR_MD = "${pkgs.marktext}/bin/marktext";
          DIFF_TOOL = "${pkgs.meld}/bin/meld";
          MERGE_TOOL = "${pkgs.meld}/bin/meld";

          # Directories
          BIN_PATH = "$HOME/.local/bin";
          LIB_PATH = "$HOME/.local/lib";
          DOTFILES_DIR = "$HOME/code/dotfiles";
          CACHE_DIR = "$HOME/.cache";
          CODE_DIR = "$HOME/code";
          WALLPAPER_DIR = "$HOME/Pictures/wallpapers";

          # path where different age keys are stored
          AGE_KEY_DIR = "$HOME/.age";

          ADW_DISABLE_PORTAL = "1";

        };

        # PATH
        sessionPath = [
          "$HOME/.local/bin"
          "$HOME/.cargo/bin"
          "$HOME/.config/hypr/scripts"
          "/var/lib/flatpak/exports/share/applications"
          "/usr/bin"
        ];

        # Cursor is owned by Stylix (modules/stylix, stylix.cursor) - do not
        # set home.pointerCursor here, it conflicts.

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

      # qt and gtk (theme/icon/cursor) are owned by Stylix (modules/stylix) -
      # do not set them here, they conflict.

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

      # Light/dark preference is owned by Stylix (stylix.polarity, per
      # theme) - do not set dconf's color-scheme here, it'd disagree.

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

          # Only the private half of each key is stored in sops - the
          # public half is derived on home-manager activation from the
          # private key (see modules/ssh.nix, home.activation.deriveSshPubkeys),
          # since it's trivially reproducible and isn't secret.
          ssh_key_private = {
            sopsFile = ../encrypted/ssh_keys.yaml;
            key = "private/priv";
            path = "${config.home.homeDirectory}/.ssh/private";
          };

          ssh_key_uni = {
            sopsFile = ../encrypted/ssh_keys.yaml;
            key = "uni/priv";
            path = "${config.home.homeDirectory}/.ssh/uni";
          };

          ssh_key_work = {
            sopsFile = ../encrypted/ssh_keys.yaml;
            key = "work/priv";
            path = "${config.home.homeDirectory}/.ssh/work";
          };

          # API Keys and Access Tokens
          "api/openai" = {
            key = "api_keys/openai";
          };

          "api/openrouter" = {
            key = "api_keys/openrouter";
          };

          "access/github" = {
            key = "access_token/github";
          };

          "access/opencode" = {
            key = "access_token/opencode";
          };

        };
      };

      # load the data from the files into environment variables
      programs.zsh.initContent = ''
        export GITHUB_TOKEN="$(cat ${config.sops.secrets."access/github".path})"
        export OPENROUTER_API_KEY="$(cat ${config.sops.secrets."api/openrouter".path})"
        export OPENCODE_SERVER_USERNAME="benjamin"
        export OPENCODE_SERVER_PASSWORD="$(cat ${config.sops.secrets."access/opencode".path})"
      '';

    }
  );
}
