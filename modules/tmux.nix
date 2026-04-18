{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
        programs.tmux = {
          enable = true;
          clock24 = true;
          keyMode = "vi";
          prefix = "C-a";
          mouse = true;
          baseIndex = 1;
          # Home Manager handles the shell path automatically if you just give the package
          shell = "${pkgs.zsh}/bin/zsh";

          # These are specific Home Manager abstractions
          shortcut = "a"; # This often works in tandem with prefix
          newSession = true; # Automatically spawn a session if one doesn't exist

          extraConfig = ''
            # Compatibility for 24-bit color
            set-option -ga terminal-overrides ",xterm-256color:Tc"

            # Better split commands
            bind | split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"

            # Easy config reload
            bind r source-file ~/.config/tmux/tmux.conf \; display "Config Reloaded!"
          '';

          plugins = with pkgs.tmuxPlugins; [
            {
              plugin = catppuccin;
              extraConfig = ''
                set -g @catppuccin_flavor 'mocha'
                set -g @catppuccin_window_status_style "rounded"
              '';
            }
            resurrect
            continuum
            vim-tmux-navigator
          ];
        };
      };
}
