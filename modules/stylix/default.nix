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
  # Stylix is structurally always on - there is no cfg.stylix.enable. The
  # only configurable surface is which curated theme is selected.
  stylix.enable = true;

  # Let Stylix theme every installed, supported application instead of
  # hand-listing every stylix.targets.<x>.enable. GNOME's and KDE's targets
  # already self-gate on whether that desktop's services are enabled;
  # qutebrowser is explicitly opted out below (own bespoke theming.py) and
  # KDE's target (home-manager only, doesn't self-gate) is tied to
  # cfg.desktop.plasma.enable below too.
  stylix.autoEnable = true;

  stylix.base16Scheme = selected.base16Scheme;
  stylix.polarity = selected.polarity;
  stylix.image = selected.image;

  stylix.fonts = {
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

  # Per-host base size (cfg.stylix.fontsize, see cfg.nix) - not every host
  # has the same screen/DPI. Feeds every app themed via
  # fonts.sizes.applications (halloy, zed, firefox, ...).
  stylix.fonts.sizes.applications = config.cfg.stylix.fontsize;

  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  stylix.opacity = {
    terminal = 1.0;
    applications = 1.0;
    desktop = 1.0;
    popups = 1.0;
  };

  # programs.nvf is configured at the NixOS level in this repo
  # (modules/neovim, via nvf.nixosModules.default - not home-manager), so
  # its Stylix target override belongs here, not in the home-manager.
  # sharedModules block below. Stylix's nvf target only sets the
  # (now-deprecated) vim.statusline.lualine.theme option for the "base16"
  # plugin variant. "mini-base16" renders the same base16-colors through
  # nvf's mini.nvim-based implementation instead, without the deprecated
  # assignment; modules/neovim/looks.nix restores the lualine statusline
  # coloring at the current option path.
  stylix.targets.nvf.plugin = "mini-base16";

  # Home-manager-level target overrides. Stylix's NixOS module
  # auto-imports its home-manager module for every `home-manager.users.*`
  # entry and copies the options above down automatically
  # (stylix.homeManagerIntegration), so per-user target tweaks belong here
  # rather than duplicated in users/benjamin.nix.
  home-manager.sharedModules = [
    (
      { osConfig, ... }:
      {
        # KDE's Stylix target lives entirely at the home-manager level and,
        # unlike GNOME's, doesn't self-gate on whether Plasma is actually
        # installed - tie it to cfg.desktop.plasma.enable explicitly so it
        # doesn't write Plasma theme files on hosts that never run Plasma.
        stylix.targets.kde.enable = osConfig.cfg.desktop.plasma.enable;

        # qutebrowser keeps its own bespoke theming (modules/qutebrowser) -
        # deliberately out of scope for Stylix.
        stylix.targets.qutebrowser.enable = false;

        # hyprpaper is deliberately disabled (modules/hyprland/hyprpaper.nix -
        # noctalia-shell manages the wallpaper instead). Without this,
        # Stylix's hyprland target auto-enables hyprpaper (as a sub-target,
        # `stylix.targets.hyprland.hyprpaper`) because a theme image is set,
        # conflicting with that explicit `services.hyprpaper.enable = false;`.
        stylix.targets.hyprland.hyprpaper.enable = false;
        stylix.targets.hyprpaper.enable = false;
        stylix.targets.noctalia.enable = true;

        # rofi isn't used anywhere in this repo (fuzzel/wofi are the actual
        # launchers) - disable its target so Stylix doesn't touch the
        # (deprecated) programs.rofi.font option and warn on every eval.
        stylix.targets.rofi.enable = false;

        # starship keeps its own deliberate, hand-tuned format/colors
        # (modules/starship.nix) - deliberately out of scope for Stylix.
        stylix.targets.starship.enable = false;

      }
    )
  ];
}
