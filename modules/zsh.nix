{ config, pkgs, ... }:

{
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
      size = 100000;
      save = 100000;
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
}
