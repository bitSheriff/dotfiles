{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.cfg.desktop.plasma.enable {
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    # Qt platform/style is owned by Stylix's qt target (modules/stylix) -
    # it already resolves to Breeze for a Plasma-only session, do not set
    # qt.style here, it conflicts.

    environment.shells = with pkgs; [ zsh ];
  };
}
