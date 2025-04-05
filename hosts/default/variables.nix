
{

  # Hyprland Settings
  extraMonitorSettings = "";

  # Waybar Settings
  clock24h = false;

  # Program Options
  browser = "zen-browser"; # Set Default Browser (google-chrome-stable for google-chrome)
  terminal = "ghostty"; # Set Default System Terminal

  keyboardLayout = "de";
  consoleKeyMap = "de";


  # Set Stylix Image
  stylixImage = ../../wallpapers/AnimeGirlNightSky.jpg;

  # Set Waybar
  # Includes alternates such as waybar-curved.nix & waybar-ddubs.nix
  waybarChoice = ../../modules/home/waybar/waybar-simple.nix;

  # Set Animation style
  # Available options are:
  # animations-def.nix  (default)
  # animations-end4.nix (end-4 project)
  # animations-dynamic.nix (ml4w project)
  animChoice = ../../modules/home/hyprland/animations-def.nix;
}
