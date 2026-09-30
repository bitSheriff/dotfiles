{ pkgs }:

# Interactive TUI to fetch a password or a live TOTP code from the
# sops-encrypted logins file. Merges what used to be two separate scripts
# (sops-pass / sops-otp) into one: after picking a field via fzf, whether it
# behaves like "pass" (copy the raw value) or "otp" (generate a TOTP token)
# is decided purely by the field's name - no separate OTP-only mode needed.
pkgs.writeShellApplication {
  name = "pass";

  runtimeInputs = with pkgs; [
    sops
    jq
    fzf
    oath-toolkit
    wl-clipboard
  ];

  text = ''
    if [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ]; then
      echo "Usage: pass [query]"
      echo "Decrypts the SOPS opaque-binary secrets file and prompts you via"
      echo "fzf (pre-filled with [query] if given, e.g. \`pass spotify\`)."
      echo "If the selected field is named 'otp', a TOTP 2FA code is"
      echo "generated from it; otherwise the raw value is used. Either way"
      echo "the result is copied directly to your clipboard."
      exit 0
    fi

    SECRETS_FILE="${../../../encrypted/logins.txt}"
    QUERY="''${1:-}"

    # The file is stored as an opaque binary blob (not structured sops
    # yaml/json) so that key names - which services/logins even exist -
    # aren't leaked in cleartext alongside the encrypted values. Decrypting
    # it just returns the original JSON content, which we then parse with jq.
    DECRYPTED_JSON=$(sops --decrypt --input-type binary --output-type binary "$SECRETS_FILE")

    SELECTED_KEY=$(echo "$DECRYPTED_JSON" | jq -r '
      paths(scalars)
      | select(.[0] != "sops")
      | map(tostring)
      | join(".")
    ' | fzf --query="$QUERY" --header="Select a secret to copy:" --height=40% --layout=reverse)

    if [ -z "$SELECTED_KEY" ]; then
      echo "Selection canceled." >&2
      exit 0
    fi

    JQ_FILTER=$(echo "$SELECTED_KEY" | jq -R 'split(".")')
    VALUE=$(echo "$DECRYPTED_JSON" | jq -r "getpath($JQ_FILTER)" | tr -d '\n')

    if [ -z "$VALUE" ] || [ "$VALUE" = "null" ]; then
      echo "Error: Could not extract a value for '$SELECTED_KEY'" >&2
      exit 1
    fi

    if [ "''${SELECTED_KEY##*.}" = "otp" ]; then
      oathtool --totp -b "$VALUE" | tr -d '\n' | wl-copy
      echo "Generated 2FA token for '$SELECTED_KEY' and copied to clipboard!" >&2
    else
      echo -n "$VALUE" | wl-copy
      echo "'$SELECTED_KEY' copied to clipboard!" >&2
    fi
  '';
}
