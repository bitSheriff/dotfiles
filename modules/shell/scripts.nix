{
  config,
  pkgs,
  ...
}:

{
  imports = [
  ];

  home-manager.users.benjamin =
    { config, ... }:
    let
      # Define scripts as packages

      decrypt_note = pkgs.writeShellScriptBin "decrypt_note" ''
        # Check if the age command is installed
        if ! command -v ${pkgs.age}/bin/age &> /dev/null; then
            echo "age command could not be found."
            exit 1
        fi

        # Check if a file is provided as an argument
        if [ -z "$1" ]; then
            echo "Usage: $0 <markdown-file>"
            exit 1
        fi

        # Read the markdown file
        file="$1"

        # Extract the age-encrypted section
        encrypted_section=$(awk '/```age/{flag=1; next} /```/{flag=0} flag' "$file")

        # Check if an encrypted section was found
        if [ -z "$encrypted_section" ]; then
            echo "No age-encrypted section found in the file."
            exit 1
        fi

        # Decrypt the section using age
        decrypted_text=$(echo "$encrypted_section" | ${pkgs.age}/bin/age -d)

        # Check if glow is installed
        if command -v ${pkgs.glow}/bin/glow &> /dev/null; then
            # print the formatted text with glow
            echo "$decrypted_text" | ${pkgs.glow}/bin/glow -
        else
            echo "$decrypted_text"
        fi
      '';

      dos2unix-dir = pkgs.writeShellScriptBin "dos2unix-dir" ''
        if [ "$#" -ne 1 ]; then
            echo "Usage: $0 <directory>"
            exit 1
        fi
        directory="$1"
        if [ ! -d "$directory" ]; then
            echo "Error: $directory is not a valid directory."
            exit 1
        fi
        find "$directory" -type f -name "*.sh" -exec ${pkgs.dos2unix}/bin/dos2unix {} \;
        echo "Completed dos2unix on all .sh files in $directory."
      '';

      encrypted_memo = pkgs.writeShellScriptBin "encrypted_memo" ''
        JOURNAL=~/notes/Journal/Entries/Daily/$(date +"%F").md
        if [ $# -gt 0 ]; then
            input="$*"
        else
            input=$(${pkgs.gum}/bin/gum write --header "Memo" --show-line-numbers --char-limit 0)
        fi
        encrypted_input=$(echo "$input" | ${pkgs.age}/bin/age -e -a -p )
        formatted=$(printf '%s\n%s\n%s' '```age' "$encrypted_input" '```')
        echo "$formatted" >> "$JOURNAL"
      '';

      floatui = pkgs.writeShellScriptBin "floatui" ''
        declare -rA LUT=(
            [audio]="wiremix"
            [bluetooth]="bluetui"
            [calc]="qalc"
            [files]="yazi $HOME"
            [ipscan]="whosthere"
            [jellyfin]="jellyfin-tui"
            [mastodon]="toot tui"
            [matrix]="iamb"
            [memo]="memo"
            [monitor]="monitui"
            [music]="kew ."
            [notes]="notes"
            [timer]="timr"
            [todo]="todo"
            [wifi]="sudo impala"
        )

        choice=$1
        cmd=''${LUT[''${choice}]}

        if test -z "''${cmd}"; then
            echo "Key ''${choice} does not exist"
            exit 1
        fi

        (eval "${pkgs.kitty}/bin/kitty --class floatui-''${choice} -e ''${cmd}") &
        disown
      '';

      gopen = pkgs.writeShellScriptBin "gopen" ''
        open_url() {
            local url=$1
            echo -e "opening ''${base_url}/\e[32m''${org_repo}\e[0m"
            ${pkgs.python3}/bin/python3 -c "import webbrowser; webbrowser.open_new_tab('''''${url}')"
        }

        origin=$(git remote get-url origin 2>/dev/null)

        if [[ $? -ne 0 ]]; then
            echo "No remote 'origin' found. Selecting a remote with fzf..."
            remote=$(git remote -v | awk '{print $2}' | ${pkgs.fzf}/bin/fzf --prompt="Select a remote: ")
            if [[ -z "''${remote}" ]]; then
                echo "No remote selected. Opening current directory in the browser..."
                open_url "file://''${PWD}"
                exit 0
            else
                origin=''${remote}
            fi
        fi

        if [[ "''${origin}" == *github.com* ]]; then
            base_url="https://github.com"
        elif [[ "''${origin}" == *gitlab.com* ]]; then
            base_url="https://gitlab.com"
        elif [[ "''${origin}" == *codeberg.org* ]]; then
            base_url="https://codeberg.org"
        else
            echo "Unsupported git hosting service."
            exit 1
        fi

        org_repo=$(echo "''${origin%.git}" | cut -f2 -d: | sed 's/.*@//')
        url="''${base_url}/''${org_repo}"
        open_url "''${url}"
      '';

      randomselect = pkgs.writeShellScriptBin "randomselect" ''
        if [ "$#" -eq 0 ]; then
            echo "Usage: $0 string1 string2 ... stringN"
            exit 1
        fi
        random_index=$((RANDOM % $#))
        echo "''${@:$((random_index + 1)):1}"
      '';

      templates = pkgs.writeShellApplication {
        name = "templates";
        runtimeInputs = [
          pkgs.nix
          pkgs.gum
          pkgs.jq
        ];
        text = ''
          DOTFILES_DIR="''${DOTFILES_DIR:-$HOME/code/dotfiles}"

          if [ ! -d "''${DOTFILES_DIR}" ]; then
              echo "Error: Dotfiles directory not found at ''${DOTFILES_DIR}" >&2
              exit 1
          fi

          selected=$(nix flake show --json "''${DOTFILES_DIR}" --extra-experimental-features "nix-command flakes" 2>/dev/null | \
                     jq -r '.templates | to_entries[] | "\(.key) - \(.value.description)"' | \
                     gum choose --header "Select a template to initialize:" || true)

          if [ -z "''${selected}" ]; then
              echo "No template selected. Exiting."
              exit 0
          fi

          template="''${selected%% *}"

          echo "Initializing template \"''${template}\"..."
          nix flake init -t "''${DOTFILES_DIR}#''${template}" --extra-experimental-features "nix-command flakes"
        '';
      };

      worktree-init = pkgs.writeShellScriptBin "worktree-init" ''
        url=''${1}
        dir=''${2}
        mkdir ''${dir}
        cd ''${dir}
        git clone --bare ''${url} .bare
        echo "gitdir: ./.bare" >.git
        git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
        git fetch
        git for-each-ref --format='%(refname:short)' refs/heads | xargs -n1 -I{} git branch --set-upstream-to=origin/{}
        git worktree add main
      '';

      ytd = pkgs.writeShellScriptBin "ytd" ''
        array_contains() {
            local list=("$@")
            local item="''${list[-1]}"
            unset 'list[''${#list[@]}-1]'
            for element in "''${list[@]}"; do
                if [[ "$element" == "$item" ]]; then return 0; fi
            done
            return 1
        }
        opts=()
        array=()
        get_options() {
            if array_contains "''${array[@]}" "simple mp3"; then
                opts+=("--extract-audio" "--audio-format" "mp3")
            elif array_contains "''${array[@]}" "high quality mp3"; then
                opts+=("-f" "bestaudio" "-x" "--audio-format" "mp3" "--audio-quality" "320k")
            fi
            if array_contains "''${array[@]}" "split chapters"; then opts+=("--split-chapters"); fi
            if array_contains "''${array[@]}" "add thumbnail"; then opts+=("--embed-thumbnail"); fi
        }
        input="$@"
        selection=$(${pkgs.gum}/bin/gum choose --no-limit "simple mp3" "high quality mp3" "add thumbnail" "split chapters")
        IFS=$'\n' read -rd "" -a array <<<"$selection"
        get_options
        ${pkgs.yt-dlp}/bin/yt-dlp "''${opts[@]}" "$@"
      '';

      z = pkgs.writeShellScriptBin "z" ''
        if [[ $# == 0 ]]; then exit 1; fi
        EXT=''${1##*.}
        if [[ "$EXT" == "pdf" ]]; then
            ${pkgs.zathura}/bin/zathura "$1"
        elif [[ "$EXT" == "md" ]]; then
            tempFile="/tmp/''${1%%.*}.pdf"
            ${pkgs.pandoc}/bin/pandoc "$1" -o "$tempFile"
            ${pkgs.zathura}/bin/zathura "$tempFile"
        else
            echo "Only PDF or MD files!"
            exit 1
        fi
      '';
    in
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

          function updir() {
              local UPDIR_LVL=''${1:-1}
              local UPDIR=""
              for i in $(seq 1 $UPDIR_LVL); do
                  UPDIR="$UPDIR../"
              done
              cd "$UPDIR"
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

        decrypt_note
        dos2unix-dir
        encrypted_memo
        floatui
        gopen
        randomselect
        templates
        worktree-init
        ytd
        z
      ];

    };
}
