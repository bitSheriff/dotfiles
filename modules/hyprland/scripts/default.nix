# The Hyprland helper scripts.
#
# Mirrors the pattern used by ../../notes/scripts/default.nix: each script
# lives in its own file (self-contained, own PATH) and this file wires them
# up as a NixOS module, installing them into environment.systemPackages.
{ pkgs, ... }:

let
  zen-mode = import ./zen-mode.nix { inherit pkgs; };
in
{
  environment.systemPackages = [ zen-mode ];
}
