{ config, pkgs, ... }:

{
  imports = [
    ./starship.nix
    ./zellij.nix
  ];

  home-manager.users.benjamin =
    { config, ... }:
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        dotDir = "${config.xdg.configHome}/zsh";

        initContent = ''
          # Disable flow control to allow CTRL-S and CTRL-Q
          stty -ixon

          # Failsafe source method
          include () {
              [[ -f "$1" ]] && source "$1"
          }

          # Tool initializations that don't have HM modules or need custom flags
          eval "$(tv init zsh)"
          eval "$(zoxide init zsh --cmd cd)"

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

        shellAliases = {
          # Git related stuff
          gti = "git";
          lg = "lazygit";
          gb = "git branch | fzf --preview 'git show --color=always {-1}' --bind 'enter:become(git checkout {-1})'";
          gg = "serie"; # git graph
          gd = "(cd $DOTFILES_DIR && just commit-all)"; # switch for a subshell into the dotfiles directory and open git
          gn = "(cd $NOTES_DIR && lazygit)"; # switch to notes directory and open git TUI

          # application shortcuts
          nv = "nvim";
          benjavim = "nvim";
          rmrf = "rm -rf";
          cp = "cp -r"; # always copy recursive
          exp = "nemo .";
          "disown!" = "exec '$@' & ; disown"; # start a process and disown it
          sshs = "sshs --config ~/.ssh/hosts"; # use own file for the SSH Hosts
          open = "xdg-open"; # open file with standard program
          cat = "bat"; # better cat command

          # directory
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          mkdir = "mkdir -p"; # always allow creating nested folders
          "mkdir!" = "mkdir -p '$1' && cd '$1'"; # create new directory and move into it
          dots = "cd $DOTFILES_DIR"; # change to the dotfiles directory
          "cd!" = "cd $(fd  --type d --hidden --exclude .git | fzf --ignore-case --no-preview )"; # change directory with fuzzy finder
          count = "'find . -type f | wc -l'"; # count files in the current directory

          nix-switch = "sudo nixos-rebuild switch --flake .#$(hostname)";
          nix-test = "sudo nixos-rebuild test --flake .#$(hostname)";
          nix-update = "nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)";

          ":q" = "exit"; # quit terminal like vim
          ":c" = "clear"; # clear terminal
          ":r" = "exec zsh"; # update zsh

          ## Rsync with default flags
          # -h ... human readable sizes
          # -a ... archive (preserve attributes)
          # -P ... partial files, if connection lost, not everything has to be copied again
          # --info=progress2 ... show progress of all files not only the current one
          # -z ... compress, better for remote transfer
          "rsync!" = "rsync -ahPz --info=progress2";

          # backup file
          bk = "cp '$1' '$1.bk'";

          # print md5 checksum of file
          md5 = "echo -n '$1' | md5sum";

          # view all git repositories and open selected in lazygit
          lgall = "lazygit -p $(tv git-repos)";

          # copy file content to clipboard
          yank = "cat $(tc files) | wl-copy";

          sync = "rsync -rtu '$1' '$2' && rsync -rtu '$2' '$1'";

        };

        history = {
          size = 100000;
          save = 100000;
          path = "$HOME/.zsh_history";
          ignoreAllDups = true;
          share = true;
        };
      };

      # little scripts
      home.packages = [
        # oen Man in neovim
        (pkgs.writeShellScriptBin "search_man" ''
          man "$1" | grep -- "$2"
        '')

        # better yazi with move to directory when exit
        (pkgs.writeShellScriptBin "y" ''
          	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          	yazi "$@" --cwd-file="$tmp"
          	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          		builtin cd -- "$cwd"
          	fi
          	rm -f -- "$tmp"
        '')

        # get fc history and edit the selected one
        (pkgs.writeShellScriptBin "fcf" ''
          # 1. Get the history list from the first command (fc -l 1) and pipe it to fzf.
          #    --tac: Shows the most recent commands at the top.
          #    --no-sort: Keeps the history order intact.
          # 2. Capture the user's selected line.
          local selected_line
          selected_line=$(fc -l 1 | fzf --tac --no-sort)

          # Check if a selection was made (user didn't press Esc or Ctrl+C)
          if [[ -n "$selected_line" ]]; then
              # 3. Extract the command number (the first column) using awk.
              local selected_number
              selected_number=$(echo "$selected_line" | awk '{print $1}')

              # 4. Use 'fc' to open the selected command number in the editor.
              #    fc 1234 is equivalent to fc -e ${"EDITOR:-vi"} 1234
              echo "Opening command #$selected_number in editor..."
              fc "$selected_number"
          else
              echo "No command selected. Aborting fc."
          fi
        '')
      ];

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

    };
}
