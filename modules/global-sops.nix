{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  dotfiles_path,
  ...
}:
let
  sops_pass = pkgs.writeShellApplication {
    name = "sops-pass";

    # Nix automatically puts these packages into the script's PATH at runtime
    runtimeInputs = with pkgs; [
      sops
      jq
      fzf
      wl-clipboard
    ];

    text = ''
      if [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ]; then
        echo "Usage: sops-pass [path/to/secrets.yaml]"
        echo "Flattens a SOPS encrypted YAML file, prompts you via fzf,"
        echo "and copies the decrypted value directly to your clipboard."
        exit 0
      fi

      SECRETS_FILE="''${1:-${../encrypted/secrets.yaml}}"

      if [ ! -f "$SECRETS_FILE" ]; then
        echo "Error: Secrets file '$SECRETS_FILE' not found." >&2
        exit 1
      fi

      DECRYPTED_JSON=$(sops --decrypt --input-type yaml --output-type json "$SECRETS_FILE")

      SELECTED_KEY=$(echo "$DECRYPTED_JSON" | jq -r '
        paths(scalars) 
        | select(.[0] != "sops") 
        | map(tostring) 
        | join(".")
      ' | fzf --header="Select a secret to copy:" --height=40% --layout=reverse)

      if [ -z "$SELECTED_KEY" ]; then
        echo "Selection canceled." >&2
        exit 0
      fi

      JQ_FILTER=$(echo "$SELECTED_KEY" | jq -R 'split(".")')

      # FIXED: Changed getvaluepath to getpath
      echo "$DECRYPTED_JSON" | jq -r "getpath($JQ_FILTER)" | tr -d '\n' | wl-copy

      echo "'$SELECTED_KEY' copied to clipboard!" >&2
    '';
  };
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  environment.systemPackages = [
    sops_pass
  ];

  # System Wide Secrets
  sops = {
    defaultSopsFile = ../encrypted/secrets.yaml;
    secrets = {
      # User passwords
      user-benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
        key = "hosts/${config.networking.hostName}/benjamin";
        neededForUsers = true;
      };

      "nix_cache_priv" = {
        key = "nix/cache/rhodos/priv";
      };

      codeberg_runner_token = {
        key = "access_token/forgejo_runner/codeberg/token";
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
}
