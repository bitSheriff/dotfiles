# Kanagawa.
#
# Plain data only: base16 colorscheme source, polarity, and a default
# wallpaper. No option declarations or target-enabling logic belong here -
# see modules/stylix/default.nix for that.
{ pkgs, ... }:
{
  base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
  polarity = "dark";

  image = pkgs.runCommand "kanagawa-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 1920x1080 xc:'#1f1f28' "$out"
  '';
}
