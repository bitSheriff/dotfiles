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

        # Apps with their own deliberate, hand-tuned theme that are outside
        # this change's explicit coverage (proposal.md: kitty, neovim,
        # fuzzel, wofi, GTK, Qt, Zed, Firefox) keep their existing look
        # instead of being silently re-themed by `stylix.autoEnable`.
        stylix.targets.opencode.enable = false;
        stylix.targets.zathura.enable = false;
        stylix.targets.halloy.enable = false;
      }
    )
  ];
}
