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

  home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.gitconfig";
  home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.ssh";
  home.file.".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/../bin";

  home.username = "benjamin";
  home.homeDirectory = "/home/benjamin";
  home.stateVersion = "25.11";

  home.sessionVariables = {
    ADW_DISABLE_PORTAL = "1"; # Force libadwaita to use dark mode
    GTK_THEME = "Adwaita:dark"; # Fallback for some GTK apps
  };

  xdg.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    initContent = ''
      # Failsafe source method
      include () {
          [[ -f "$1" ]] && source "$1"
      }

      # Include your existing modular config files
      include ~/.config/shell/envvars
      include ~/.config/shell/autostart
      include ~/.config/shell/secrets
      include ~/.config/shell/options
      include ~/.config/shell/alias

      # Tool initializations that don't have HM modules or need custom flags
      eval "$(tv init zsh)"

      # Ghostty integration
      if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
        source $GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration
      fi

      # Custom completions
      _just_completion() {
          if [[ -f "justfile" ]]; then
            local options
            options="$(just --summary)"
            reply=(''${(s: :)options})
          fi
      }
      compctl -K _just_completion just
    '';

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
      share = true;
    };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true; # Enable if you use any XWayland apps
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
