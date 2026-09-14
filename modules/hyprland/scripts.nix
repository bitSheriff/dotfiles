# The Hyprland helper scripts, as plain derivations.
#
# Mirrors the pattern used by ../hledger/scripts.nix: this file takes only
# `pkgs` and returns packages, keeping the scripts self-contained (own PATH)
# and reusable outside the NixOS module system if ever needed.
{ pkgs }:

{
  # Zen mode: hides distractions on the focused workspace so you can focus on
  # a single window. Toggled by SUPER + CTRL + W (see config/binds.lua).
  #
  # On:
  #   - fullscreens the focused window (hyprctl dispatch fullscreen 1)
  #   - zeroes gaps & borders (restored to their real values on exit, not
  #     hardcoded, so this keeps working if options.lua changes them)
  #   - forces full opacity (1.0) on all windows
  #   - hides the noctalia bar
  #   - enables the idle inhibitor, so the session doesn't lock/sleep mid-zen
  #
  # Off: reverses all of the above, using values captured in a state file at
  # $XDG_RUNTIME_DIR/zen-mode.state (tmpfs, cleared on logout/reboot).
  zen-mode = pkgs.writeShellApplication {
    name = "zen-mode";
    runtimeInputs = with pkgs; [
      hyprland # hyprctl
      jq
      noctalia-shell
      coreutils
    ];
    text = ''
      # This config uses Hyprland's native Lua config (configType = "lua"),
      # so the classic `hyprctl keyword`/`--batch` verbs are rejected at
      # runtime ("keyword can't work with non-legacy parsers. Use eval.").
      # Runtime changes instead go through `hyprctl eval "<lua>"`, calling
      # the same hl.config()/hl.dispatch() API the *.lua config files use.
      STATE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/zen-mode.state"

      hypr_eval() {
        hyprctl eval "$1" >/dev/null
      }

      hypr_num() {
        # Extract a leading numeric value from `hyprctl getoption -j`,
        # whether it's reported as "int" (border_size), "float" (opacity),
        # or a space-separated "css" value (gaps_in/gaps_out, e.g. "5 5 5 5").
        hyprctl getoption "$1" -j | jq -r '.int // .float // (.css | split(" ")[0])'
      }

      if [ -f "$STATE_FILE" ]; then
        # --- Zen mode is ON: turn it OFF and restore previous values ---
        # shellcheck source=/dev/null
        source "$STATE_FILE"

        hypr_eval "hl.config({ general = { gaps_in = $ZEN_GAPS_IN, gaps_out = $ZEN_GAPS_OUT, border_size = $ZEN_BORDER_SIZE }, decoration = { active_opacity = $ZEN_ACTIVE_OPACITY, inactive_opacity = $ZEN_INACTIVE_OPACITY } })"
        hypr_eval "hl.dispatch(hl.dsp.window.fullscreen({action = 'toggle'}))"

        noctalia-shell ipc call bar showBar >/dev/null 2>&1 || true
        noctalia-shell ipc call idleInhibitor disable >/dev/null 2>&1 || true

        rm -f "$STATE_FILE"
      else
        # --- Zen mode is OFF: turn it ON, remembering current values ---
        {
          echo "ZEN_GAPS_IN=$(hypr_num general:gaps_in)"
          echo "ZEN_GAPS_OUT=$(hypr_num general:gaps_out)"
          echo "ZEN_BORDER_SIZE=$(hypr_num general:border_size)"
          echo "ZEN_ACTIVE_OPACITY=$(hypr_num decoration:active_opacity)"
          echo "ZEN_INACTIVE_OPACITY=$(hypr_num decoration:inactive_opacity)"
        } > "$STATE_FILE"

        hypr_eval "hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { active_opacity = 1.0, inactive_opacity = 1.0 } })"
        hypr_eval "hl.dispatch(hl.dsp.window.fullscreen({action = 'toggle'}))"

        noctalia-shell ipc call bar hideBar >/dev/null 2>&1 || true
        noctalia-shell ipc call idleInhibitor enable >/dev/null 2>&1 || true
      fi
    '';
  };
}
