# System-wide theming (Stylix). Always on - see cfg.nix `cfg.stylix.theme`
# for the single knob exposed to hosts. Curated themes live in ./themes;
# this file only holds the shared, theme-independent defaults and the
# dispatch from `cfg.stylix.theme` to the selected theme's data.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  themes = {
    catppuccin-mocha = import ./themes/catppuccin-mocha.nix { inherit pkgs; };
    dracula = import ./themes/dracula.nix { inherit pkgs; };
    gruvbox-dark = import ./themes/gruvbox-dark.nix { inherit pkgs; };
    nord = import ./themes/nord.nix { inherit pkgs; };
    booberry = import ./themes/booberry.nix { inherit pkgs; };
    kanagawa = import ./themes/kanagawa.nix { inherit pkgs; };
  };

  selected = themes.${config.cfg.stylix.theme};
in
{

  stylix = {

    enable = true;
    autoEnable = true;
    base16Scheme = selected.base16Scheme;
    polarity = selected.polarity;
    image = selected.image;

    fonts = {
      serif = {
        package = pkgs.comic-neue;
        name = "Comic Neue";
      };
      sansSerif = {
        package = pkgs.comic-neue;
        name = "Comic Neue";
      };
      monospace = {
        package = pkgs.comic-mono;
        name = "Comic Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };

    # Per-host base size (cfg.stylix.fontsize, see cfg.nix) - not every host has the same screen/DPI.
    fonts.sizes.applications = config.cfg.stylix.fontsize;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    opacity = {
      terminal = 1.0;
      applications = 1.0;
      desktop = 1.0;
      popups = 1.0;
    };

    targets.nvf.plugin = "mini-base16";
  };

  # Home-manager-level target overrides
  home-manager.sharedModules = [
    (
      { osConfig, ... }:
      {

        stylix.targets = {
          kde.enable = true;
          gnome.enable = true;
          gtk.enable = true;
          qutebrowser.enable = false;
          hyprland.hyprpaper.enable = false;
          hyprpaper.enable = false;
          noctalia.enable = true;
          rofi.enable = false;
          starship.enable = false; # use own starship config
        };

      }
    )
  ];
}
