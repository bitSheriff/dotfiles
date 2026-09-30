# Nord.
#
# Plain data only: base16 colorscheme source, polarity, and a default
# wallpaper. No option declarations or target-enabling logic belong here -
# see modules/stylix/default.nix for that.
{ pkgs, ... }:
{
  base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  polarity = "dark";

  image = pkgs.runCommand "nord-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 1920x1080 xc:'#2e3440' "$out"
  '';
}
