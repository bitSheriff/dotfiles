# WhichKey-style HUD for Hyprland submaps. Shows the active submap's bound
# keys + descriptions as a Noctalia notification; triggered from
# config/whichkey.lua on the "keybinds.submap" event.
{ pkgs }:

pkgs.writeShellApplication {
  name = "whichkey-hud";
  runtimeInputs = with pkgs; [
    hyprland # hyprctl
    jq
    noctalia # provides `noctalia msg ...`
  ];
  text = ''
    submap="''${1:-}"

    noctalia msg notification-clear-active >/dev/null 2>&1 || true

    if [ -z "$submap" ]; then
      exit 0
    fi

    body=$(hyprctl binds -j | jq -r --arg sm "$submap" '
      def modstr:
        ( if (. / 64 | floor) % 2 == 1 then "SUPER + " else "" end )
        + ( if (. / 8 | floor) % 2 == 1 then "ALT + " else "" end )
        + ( if (. / 4 | floor) % 2 == 1 then "CTRL + " else "" end )
        + ( if (. / 1 | floor) % 2 == 1 then "SHIFT + " else "" end );
      [ .[] | select(.submap == $sm and .has_description) ]
      | sort_by(.key)
      | map("\(.modmask | modstr)\(.key)  →  \(.description)")
      | join("\n")
    ')

    if [ -z "$body" ]; then
      exit 0
    fi

    payload=$(jq -n --arg summary "Submap: $submap" --arg body "$body" '{
      app_name: "WhichKey",
      summary: $summary,
      body: $body,
      urgency: "low",
      timeout_ms: 0,
      icon: "keyboard"
    }')

    noctalia msg notification-show "$payload"
  '';
}
