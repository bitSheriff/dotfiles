# Searchable WhichKey: SUPER + ? lists the exec-backed binds from binds.lua
# through cfg.apps.menu (dmenu-protocol picker) and runs the chosen command
# directly.
#
# This deliberately does NOT try to replay the keypress (e.g. via wtype):
# Hyprland only processes compositor-level keybinds from real input devices,
# not from the wlr-virtual-keyboard protocol, so a synthesized keypress never
# reaches the bind dispatcher. Running the command directly sidesteps that,
# and matches exactly what hl.dsp.exec_cmd() would have run anyway. See
# config/binds.lua's wk_exec_bind()/wk_dump_exec() for the manifest this
# reads - it's the single source of truth, not a reflection of hyprctl binds.
{ pkgs, menuCmd }:

pkgs.writeShellApplication {
  name = "whichkey-search";
  runtimeInputs = with pkgs; [
    jq
    gawk
    coreutils
  ];
  text = ''
    manifest="''${XDG_RUNTIME_DIR:-/tmp}/whichkey-exec.json"
    [ -s "$manifest" ] || exit 0

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT

    jq -r 'sort_by(.desc)[] | [(.key + "  →  " + .desc), .cmd] | @tsv' "$manifest" > "$tmp"
    [ -s "$tmp" ] || exit 0

    selected=$(cut -f1 "$tmp" | ${menuCmd})
    [ -n "$selected" ] || exit 0

    cmd=$(awk -F'\t' -v sel="$selected" '$1 == sel { print $2; exit }' "$tmp")
    [ -n "$cmd" ] || exit 0

    sh -c "$cmd" &
    disown
  '';
}
