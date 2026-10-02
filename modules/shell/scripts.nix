# The shell helper scripts, as plain derivations.
#
# Mirrors the pattern used by ../hledger/scripts.nix: this file takes only
# `pkgs` and returns packages, keeping the scripts self-contained and
# decoupled from home-manager/NixOS module wiring, which lives in ./zsh.nix.
{ pkgs }:

{
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
        [pass]="pass"
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

  # Bootstraps a machine with one of the flake's NixOS configurations: wipes
  # its disks according to the configuration's disko layout and installs the
  # system. Asks for the target and the configuration interactively.
  #
  # With a host it drives the real nixos-anywhere over SSH (hence the absolute
  # store path below - this script shadows its name). Without one it installs
  # onto the machine it runs on, which only works from the NixOS installer:
  # nixos-anywhere can't replace the system it is itself running from, so that
  # case does the same two steps (disko, nixos-install) locally.
  nixos-anywhere = pkgs.writeShellApplication {
    name = "nixos-anywhere";
    runtimeInputs = [
      pkgs.nix
      pkgs.gum
      pkgs.jq
    ];
    text = ''
      # Normally the local checkout, but DOTFILES_DIR may also hold any flake
      # reference (e.g. github:bitSheriff/dotfiles), which is what makes this
      # usable on an installer without a checkout.
      FLAKE="''${DOTFILES_DIR:-$HOME/code/dotfiles}"
      NIX=(nix --extra-experimental-features "nix-command flakes")

      # Owner of the age key on the new system: the first normal user and the
      # `users` group. The uid isn't pinned in the config, NixOS hands out 1000.
      KEY_OWNER="1000:100"

      case "$FLAKE" in
          *:*) ;; # a flake reference, resolved by nix
          *)
              if [ ! -e "$FLAKE/flake.nix" ]; then
                  echo "Error: no flake found at $FLAKE" >&2
                  echo "Set DOTFILES_DIR to a checkout or to a flake reference like github:owner/repo." >&2
                  exit 1
              fi
              ;;
      esac

      host=$(gum input --header "Target host (IP address or name)" --placeholder "empty: this machine")
      user=$(gum input --header "User on the target" --placeholder "empty: root, or you ($USER) for this machine")

      if [ -z "$host" ] && [ -n "$user" ]; then
          echo "Error: a user was given without a host." >&2
          exit 1
      fi

      if [ -z "$host" ]; then
          target="this machine ($(hostname), as $USER)"
          if ! grep -qE '^VARIANT_ID="?installer"?$' /etc/os-release; then
              echo "Error: this machine is running from the disk that would be erased." >&2
              echo "Boot the NixOS installer on it and run this again, or run it from" >&2
              echo "another machine with this one as the target host." >&2
              exit 1
          fi
      else
          target="''${user:-root}@$host"
      fi

      config=$("''${NIX[@]}" eval --json "$FLAKE#nixosConfigurations" --apply builtins.attrNames \
               | jq -r '.[]' \
               | gum choose --header "Which configuration should be installed on $target?" || true)

      if [ -z "$config" ]; then
          echo "No configuration selected. Exiting."
          exit 0
      fi

      attr="$FLAKE#nixosConfigurations.$config.config"

      echo "Checking the \"$config\" configuration..."
      disks=$("''${NIX[@]}" eval --json "$attr.disko.devices.disk" --apply 'builtins.mapAttrs (_: d: d.device)' \
              | jq -r 'to_entries[] | "  \(.key): \(.value)"')

      if [ -z "$disks" ]; then
          echo "Error: \"$config\" has no disko layout, so there is nothing to partition" >&2
          echo "the target with. Is ./disko.nix imported in hosts/$config/default.nix?" >&2
          exit 1
      fi

      # The disks are erased before the system gets built, so make sure the
      # configuration evaluates while nothing has been touched yet.
      "''${NIX[@]}" eval --raw "$attr.system.build.toplevel.drvPath" >/dev/null

      # sops-nix decrypts the secrets (user passwords included) with this key
      # on first boot, so it has to be on the new system before that.
      key_target=$("''${NIX[@]}" eval --raw "$attr.sops.age.keyFile" 2>/dev/null || true)
      key_source=""
      key_home=""
      if [ -n "$key_target" ]; then
          key_source="''${SOPS_AGE_KEY_FILE:-$HOME/.age/dotfiles.key}"
          if [ ! -r "$key_source" ]; then
              key_source=$(gum input --header "Age key to copy to $key_target" --placeholder "path, empty: don't copy")
          fi
          if [ -n "$key_source" ] && [ ! -r "$key_source" ]; then
              echo "Error: cannot read $key_source" >&2
              exit 1
          fi
          case "$key_target" in
              /home/*) key_home=$(echo "$key_target" | cut -d/ -f1-3) ;;
          esac
      fi

      echo
      echo "Configuration: $config"
      echo "Target:        $target"
      echo "Disks that will be ERASED:"
      echo "$disks"
      if [ -n "$key_source" ]; then
          echo "Age key:       $key_source -> $key_target"
      elif [ -n "$key_target" ]; then
          echo "Age key:       NOT copied - the new system can't decrypt its secrets"
          echo "               (no login password) until $key_target exists"
      fi
      echo

      if ! gum confirm --default=false "Erase these disks and install \"$config\" on $target?"; then
          echo "Aborted, nothing was changed."
          exit 0
      fi

      if [ -z "$host" ]; then
          sudo ${pkgs.disko}/bin/disko --mode destroy,format,mount --flake "$FLAKE#$config"

          if [ -n "$key_source" ]; then
              sudo install -D -m 600 "$key_source" "/mnt$key_target"
              sudo chmod 700 "$(dirname "/mnt$key_target")"
              if [ -n "$key_home" ]; then
                  sudo chmod 700 "/mnt$key_home"
                  sudo chown -R "$KEY_OWNER" "/mnt$key_home"
              fi
          fi

          sudo ${pkgs.nixos-install-tools}/bin/nixos-install --flake "$FLAKE#$config" --no-root-passwd
          echo "Installed \"$config\". Reboot into the new system when ready."
      else
          args=(--flake "$FLAKE#$config" --target-host "$target")

          if [ -n "$key_source" ]; then
              # Staged on tmpfs, laid out like the target's root directory.
              staging=$(mktemp -d -p "''${XDG_RUNTIME_DIR:-/tmp}")
              trap 'rm -rf "$staging"' EXIT
              install -D -m 600 "$key_source" "$staging$key_target"
              chmod 700 "$(dirname "$staging$key_target")"
              args+=(--extra-files "$staging")
              if [ -n "$key_home" ]; then
                  chmod 700 "$staging$key_home"
                  args+=(--chown "$key_home" "$KEY_OWNER")
              fi
          fi

          ${pkgs.nixos-anywhere}/bin/nixos-anywhere "''${args[@]}"
      fi
    '';
  };

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

  search_man = pkgs.writeShellScriptBin "search_man" ''
    man "$1" | grep -- "$2"
  '';
}
