# Catppuccin Mocha - the default theme (modules/stylix/default.nix).
#
# Plain data only: base16 colorscheme source, polarity, and a default
# wallpaper. No option declarations or target-enabling logic belong here -
# see modules/stylix/default.nix for that.
{ pkgs, ... }:
{
  base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  polarity = "dark";

  # Solid background matching the scheme's base00, generated on the fly so
  # every theme ships a working default wallpaper without depending on
  # artwork that may not exist for it upstream.
  image = pkgs.runCommand "catppuccin-mocha-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 1920x1080 xc:'#1e1e2e' "$out"
  '';
}
