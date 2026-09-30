# Booberry - a base16 scheme derived from the old halloy "booberry" theme
# (previously hand-written in modules/irc.nix). A dark, purple/magenta IRC
# theme with green success, red error, and yellow/cyan accents.
#
# Plain data only: base16 colorscheme source, polarity, and a default
# wallpaper. No option declarations or target-enabling logic belong here -
# see modules/stylix/default.nix for that.
{ pkgs, ... }:
{
  base16Scheme = {
    system = "base16";
    name = "Booberry";
    author = "derived from halloy's booberry theme";
    variant = "dark";
    palette = {
      base00 = "#3a224c"; # buffer.background - main background
      base01 = "#452859"; # general.background - lighter background (panels/status bar)
      base02 = "#50496d"; # buffer.selection - selection background
      base03 = "#806d8d"; # buffer.timestamp - comments/invisibles
      base04 = "#ad96be"; # text.secondary - dark foreground
      base05 = "#d8c8f3"; # text.primary - default foreground
      base06 = "#eccdba"; # text.tertiary - light foreground
      base07 = "#dbbfef"; # general.border - light background
      base08 = "#f47868"; # text.error - red
      base09 = "#e8dca0"; # buffer.action - orange
      base0A = "#ffcd1d"; # buffer.server_messages.default - yellow
      base0B = "#a0f28f"; # text.success / buffer.nickname - green
      base0C = "#82cecf"; # buffer.url - cyan
      base0D = "#a4a0e8"; # buffer.border_selected - blue
      base0E = "#c1a8d3"; # buttons.secondary.background_selected_hover - purple
      base0F = "#64546f"; # buffer.highlight - deprecated/embedded
    };
  };
  polarity = "dark";

  # Solid background matching the scheme's base00, generated on the fly so
  # every theme ships a working default wallpaper without depending on
  # artwork that may not exist for it upstream.
  image = pkgs.runCommand "booberry-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 1920x1080 xc:'#3a224c' "$out"
  '';
}
