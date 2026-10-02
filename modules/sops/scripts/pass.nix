{ pkgs }:

# Interactive TUI to fetch a password, a live TOTP code, or open a login's
# URL, from the sops-encrypted logins file. Merges what used to be two
# separate scripts (sops-pass / sops-otp) into one: after picking a field via
# fzf, what happens is decided purely by the field's name - no separate
# mode flags needed:
#   - "otp"  -> generate a TOTP token and copy it
#   - "url"  -> open it with the default browser ($BROWSER via xdg-open)
#   - else   -> copy the raw value
#
# A service can have more than one URL via a [service.url] sub-table with
# descriptive sub-keys (e.g. bookorbit.url.shop, bookorbit.url.support) -
# detection below checks for "otp"/"url" anywhere in the path, not just as
# the last segment, so both the flat `url = "..."` and nested
# `[service.url]` shapes work without any script changes.
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
      echo "Usage: pass [query|tag]"
      echo "Decrypts the SOPS opaque-binary secrets file and prompts you via"
      echo "fzf (pre-filled with [query] if given, e.g. \`pass spotify\`)."
      echo "If [query] exactly matches a 'tags' entry on a service (e.g."
      echo "tags = [\"work\"]), the picker is pre-filtered to that tag's"
      echo "entries instead of doing a normal fuzzy path search."
      echo "What happens next depends on the selected field's name:"
      echo "  otp  - generate a TOTP 2FA code and copy it to the clipboard"
      echo "  url  - open it with the default browser (http/https only)"
      echo "  *    - copy the raw value to the clipboard"
      echo "Copied secrets are hidden from the clipboard history and removed"
      echo "from the clipboard again after 45 seconds."
      exit 0
    fi

    SECRETS_FILE="${../../../encrypted/pass.txt}"
    QUERY="''${1:-}"

    # Seconds until a copied secret is removed from the clipboard again.
    CLEAR_AFTER=45

    # Copies $1 to the clipboard, marked as sensitive so clipboard managers
    # (cliphist, via wl-paste --watch's CLIPBOARD_STATE) don't persist it,
    # and clears the clipboard after CLEAR_AFTER seconds - but only if it
    # still holds this secret, so anything copied in the meantime survives.
    # The secret only ever travels through builtins and pipes, never through
    # another process' argv (which would be world-readable in /proc).
    copy_secret() {
      local secret="$1"
      printf '%s' "$secret" | wl-copy --sensitive
      (
        # floatui closes the terminal as soon as this script exits; ignore
        # the resulting SIGHUP so the timer below still fires.
        trap "" HUP
        sleep "$CLEAR_AFTER"
        if [ "$(wl-paste --no-newline 2>/dev/null)" = "$secret" ]; then
          wl-copy --clear
        fi
      ) </dev/null >/dev/null 2>&1 &
    }

    # The file is stored as an opaque binary blob (not structured sops
    # yaml/json) so that key names - which services/logins even exist -
    # aren't leaked in cleartext alongside the encrypted values. The content
    # itself is plain TOML (easy to hand-edit via \`sops ${../../../encrypted/pass.txt}\`:
    # one [section] per login, no indentation rules), converted to JSON here
    # so the rest of the script can keep using jq.
    DECRYPTED_JSON=$(sops --decrypt --input-type binary --output-type binary "$SECRETS_FILE" | yq -p toml -o json .)

    TAG_MATCH=$(echo "$DECRYPTED_JSON" | jq -r --arg q "$QUERY" '
      [ to_entries[] | select(.key != "sops") | (.value.tags // [])[] ] | index($q) != null
    ')

    FZF_OPTS=(
      --no-sort
      --no-multi
      --preview=
      --cycle
      --margin=5%
      --border=double
      --layout=reverse
      --height=40%
    )

    if [ -n "$QUERY" ] && [ "$TAG_MATCH" = "true" ]; then
      SELECTED_KEY=$(echo "$DECRYPTED_JSON" | jq -r --arg tag "$QUERY" '
        to_entries[]
        | select(.key != "sops")
        | select((.value.tags // []) | index($tag) != null)
        | .key as $svc
        | (.value | del(.tags)) as $data
        | $data
        | paths(scalars) as $p
        | ([$svc] + ($p | map(tostring)) | join("."))
      ' | fzf "''${FZF_OPTS[@]}" --header="Select a secret (tag: $QUERY):")
    else
      SELECTED_KEY=$(echo "$DECRYPTED_JSON" | jq -r '
        to_entries[]
        | select(.key != "sops")
        | .key as $svc
        | (.value | del(.tags)) as $data
        | $data
        | paths(scalars) as $p
        | ([$svc] + ($p | map(tostring)) | join("."))
      ' | fzf "''${FZF_OPTS[@]}" --query="$QUERY" --header="Select a secret to copy:")
    fi

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

    # Matches "otp"/"url" as the last segment (flat field, e.g. "service.url")
    # or as any earlier segment (nested sub-table, e.g. "service.url.shop").
    case ".$SELECTED_KEY." in
      *.otp.*)
        # The seed is fed via stdin ("-"), not as an argument, to keep it
        # out of oathtool's argv.
        TOKEN=$(printf '%s' "$VALUE" | oathtool --totp -b - | tr -d '\n')
        copy_secret "$TOKEN"
        echo "Generated 2FA token for '$SELECTED_KEY' and copied to clipboard (cleared in ''${CLEAR_AFTER}s)!" >&2
        ;;
      *.url.*)
        # Only ever hand web URLs to xdg-open - never options, local files
        # or other scheme handlers.
        case "$VALUE" in
          http://* | https://*) ;;
          *)
            echo "Error: '$SELECTED_KEY' is not an http(s) URL, refusing to open it." >&2
            exit 1
            ;;
        esac
        xdg-open "$VALUE" >/dev/null 2>&1 &
        disown
        echo "Opened '$VALUE' in your browser." >&2
        ;;
      *)
        copy_secret "$VALUE"
        echo "'$SELECTED_KEY' copied to clipboard (cleared in ''${CLEAR_AFTER}s)!" >&2
        ;;
    esac
  '';
}
