# Scripts for managing this dotfiles flake itself (bootstrapping a host,
# rotating secrets, syncing the phone), as opposed to ./modules/shell/scripts.nix,
# which holds everyday shell helpers unrelated to this repository.
#
# Exposed as flake apps/packages in ./flake.nix (`nix run .#<name>`), and
# `nixos-anywhere` and `templates` are also installed into the interactive
# shell by ./modules/shell/zsh.nix since they are useful to run by hand too.
#
# Mirrors the pattern used by modules/hledger/scripts.nix: this file takes
# only `pkgs` and returns packages, keeping the scripts self-contained and
# decoupled from home-manager/NixOS module wiring.
{ pkgs }:

let
  # The appids to install on the phone. See ./hosts/android/fdroid-packages.nix.
  fdroidPackages = import ./hosts/android/fdroid-packages.nix;
in
{
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
          # Keys are per host, ~/.age/<hostname>.key, so the new host's own key
          # is looked for first under the same name here. The general key
          # (dotfiles.key) can open everything too and serves as the fallback
          # for a host whose key has not been generated yet.
          key_source="''${SOPS_AGE_KEY_FILE:-$HOME/.age/$(basename "$key_target")}"
          if [ ! -r "$key_source" ] && [ -r "$HOME/.age/dotfiles.key" ]; then
              key_source="$HOME/.age/dotfiles.key"
          fi
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

  # Re-encrypts every secret in ./encrypted for the current set of recipients
  # in .sops.yaml, e.g. after adding or removing an age key. This only
  # rewraps the existing data key for the new recipient list; it does not
  # change the data key itself, so anyone who had access to it before being
  # removed could still decrypt the old ciphertext. Use sops-rotate-keys instead
  # when a key may have been compromised or a recipient was revoked.
  sops-update-keys = pkgs.writeShellApplication {
    name = "sops-update-keys";
    runtimeInputs = [ pkgs.sops ];
    text = ''
      DOTFILES_DIR="''${DOTFILES_DIR:-$HOME/code/dotfiles}"
      cd "''${DOTFILES_DIR}"
      # The second glob catches dotfiles such as encrypted/.face.enc.
      sops updatekeys -y encrypted/* encrypted/.[!.]*
    '';
  };

  # Generates a fresh data key for every secret in ./encrypted and
  # re-encrypts their contents with it, then wraps that new data key for the
  # current recipients in .sops.yaml. Use this after revoking someone's
  # access or suspecting a key leak, since sops-update-keys alone leaves the old
  # data key (and thus old ciphertext) decryptable by anyone who had it.
  sops-rotate-keys = pkgs.writeShellApplication {
    name = "sops-rotate-keys";
    runtimeInputs = [ pkgs.sops ];
    text = ''
      DOTFILES_DIR="''${DOTFILES_DIR:-$HOME/code/dotfiles}"
      cd "''${DOTFILES_DIR}"
      # Unlike `sops updatekeys`, `sops -r -i` only rotates one file per
      # invocation - fed several positional args it silently rotates just
      # the first and warns about the rest. Rotate each file individually.
      for f in encrypted/* encrypted/.[!.]*; do
          sops -r -i "''${f}"
      done
    '';
  };

  # Two unrelated jobs behind one name, picked by where this actually runs:
  #
  # * On the phone itself, inside nix-on-droid (see ../../justfile's `android`
  #   recipe): rebuilds its own nix-on-droid config, same as `just android`.
  # * Anywhere else (the desktop/laptop): installs the F-Droid apps listed in
  #   ./hosts/android/fdroid-packages.nix onto a phone connected over ADB
  #   (USB, or wireless debugging), via fdroidcl. nix-on-droid has no notion
  #   of "its own" phone to install apps onto, so that direction only makes
  #   sense from outside.
  #
  # `command -v nix-on-droid` is the detector: that wrapper only exists on
  # PATH inside a nix-on-droid environment, from the first bootstrap on.
  # `nix run .#setup-android` either way.
  setup-android = pkgs.writeShellApplication {
    name = "setup-android";
    runtimeInputs = [
      pkgs.fdroidcl
      pkgs.android-tools # adb, started by fdroidcl itself if not already running
    ];
    text = ''
      if command -v nix-on-droid >/dev/null 2>&1; then
        echo "Running inside nix-on-droid: switching this phone's own config."
        DOTFILES_DIR="''${DOTFILES_DIR:-$HOME/code/dotfiles}"
        nix-on-droid switch --flake "''${DOTFILES_DIR}#android"
        exit 0
      fi

      apps=(
        ${pkgs.lib.concatMapStringsSep "\n        " (appid: "\"${appid}\"") fdroidPackages}
      )

      echo "Waiting for a device (USB debugging, or wireless debugging already paired)..."
      adb wait-for-device

      echo "Updating the F-Droid index..."
      fdroidcl update

      echo "Installing ''${#apps[@]} app(s): ''${apps[*]}"
      fdroidcl install "''${apps[@]}"
    '';
  };
}
