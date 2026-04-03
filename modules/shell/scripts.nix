{ config, pkgs, ... }:

{
  imports = [
  ];

  home-manager.users.benjamin =
    { config, ... }:
    {
      programs.zsh = {

        initContent = ''
          function y() {
              local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
              yazi "$@" --cwd-file="$tmp"
              if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                builtin cd -- "$cwd"
              fi
          rm -f -- "$tmp"
          }

          fcf() {
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
          }
        '';
      };

      # little scripts
      home.packages = [
        # oen Man in neovim
        (pkgs.writeShellScriptBin "search_man" ''
          man "$1" | grep -- "$2"
        '')

      ];

    };
}
