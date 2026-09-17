{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

let
  webapps = config.cfg.browser.webapps;

  # One chromeless "app mode" window + its own isolated profile dir per
  # webapp, so cookies/sessions never leak into normal browsing or between
  # webapps, and each gets a distinct taskbar window class.
  mkWebappEntry =
    homeDirectory: w: {
      name = "webapp-${w.id}";
      value = {
        name = w.name;
        genericName = "Web App";
        icon = if w.icon != null then w.icon else "web-browser";
        terminal = false;
        type = "Application";
        categories = w.categories;
        exec = "${pkgs.chromium}/bin/chromium --app=${w.url} --class=${w.id} --user-data-dir=${homeDirectory}/.local/share/webapps/${w.id}";
        settings = {
          StartupWMClass = w.id;
        };
      };
    };
in
{
  config = lib.mkIf config.cfg.browser.chromium.enable {
    environment.systemPackages = with pkgs; [
      chromium
    ];

    home-manager.users.benjamin =
      lib.mkIf (lib.elem "benjamin" activeUsers)
        (
          { config, ... }:
          {
            xdg.desktopEntries = lib.listToAttrs (
              map (mkWebappEntry config.home.homeDirectory) webapps
            );
          }
        );
  };
}
