{ pkgs }:

# Interactive TUI to fetch a password, a live TOTP code, or open a login's
# URL, from the sops-encrypted logins file. Merges what used to be two
# separate scripts (sops-pass / sops-otp) into one: after picking a field via
# fzf, what happens is decided purely by the field's name - no separate
# mode flags needed:
#   - "otp"  -> generate a TOTP token and copy it
#   - "url"  -> open it with the default browser ($BROWSER via xdg-open)
#   - else   -> copy the raw value
pkgs.writeShellApplication {
  name = "pass";

  runtimeInputs = with pkgs; [
    sops
    jq
    yq-go
    fzf
    oath-toolkit
    wl-clipboard
    xdg-utils
  ];

  text = ''
    if [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ]; then
      echo "Usage: pass [query]"
      echo "Decrypts the SOPS opaque-binary secrets file and prompts you via"
      echo "fzf (pre-filled with [query] if given, e.g. \`pass spotify\`)."
      echo "What happens next depends on the selected field's name:"
      echo "  otp  - generate a TOTP 2FA code and copy it to the clipboard"
      echo "  url  - open it with the default browser"
      echo "  *    - copy the raw value to the clipboard"
      exit 0
    fi

    SECRETS_FILE="${../../../encrypted/pass.txt}"
    QUERY="''${1:-}"

    # The file is stored as an opaque binary blob (not structured sops
    # yaml/json) so that key names - which services/logins even exist -
    # aren't leaked in cleartext alongside the encrypted values. The content
    # itself is plain YAML (easy to hand-edit via \`sops ${../../../encrypted/pass.txt}\`),
    # converted to JSON here so the rest of the script can keep using jq.
    DECRYPTED_JSON=$(sops --decrypt --input-type binary --output-type binary "$SECRETS_FILE" | yq -p yaml -o json .)

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

    FIELD="''${SELECTED_KEY##*.}"
    if [ "$FIELD" = "otp" ]; then
      oathtool --totp -b "$VALUE" | tr -d '\n' | wl-copy
      echo "Generated 2FA token for '$SELECTED_KEY' and copied to clipboard!" >&2
    elif [ "$FIELD" = "url" ]; then
      xdg-open "$VALUE" >/dev/null 2>&1 &
      disown
      echo "Opened '$VALUE' in your browser." >&2
    else
      echo -n "$VALUE" | wl-copy
      echo "'$SELECTED_KEY' copied to clipboard!" >&2
    fi
  '';
}
