# The Hyprland helper scripts.
#
# Mirrors the pattern used by ../../notes/scripts/default.nix: each script
# lives in its own file (self-contained, own PATH) and this file wires them
# up as a NixOS module, installing them into environment.systemPackages.
{ pkgs, config, ... }:

let
  zen-mode = import ./zen-mode.nix { inherit pkgs; };
  whichkey-hud = import ./whichkey.nix { inherit pkgs; };
  whichkey-search = import ./whichkey-search.nix {
    inherit pkgs;
    menuCmd = config.cfg.apps.menu;
  };
in
{
  environment.systemPackages = [
    zen-mode
    whichkey-hud
    whichkey-search
  ];
}
