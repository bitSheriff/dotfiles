# Catalog of webapp shortcuts (modules/chromium.nix turns these into
# chromeless `chromium --app=` launcher entries). Hosts enable entries via
# cfg.browser.webapp.<name>.enable (cfg.nix) instead of repeating
# name/url/icon per host; cfg.browser.webapps below is the resolved list
# that produces, kept out of cfg.nix since it's not something a host
# should author directly.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types literalExpression;

  catalog = {
    homeassistant = {
      name = "Home Assistant";
      url = "https://home.mandl-meyer.me";
      # "homeassistant" isn't a real icon name in any theme (incl. Papirus);
      # webapp logos need an actual file, not a theme lookup.
      icon = pkgs.fetchurl {
        url = "https://www.home-assistant.io/images/favicon-192x192-full.png";
        sha256 = "sha256-unax8LuUpOsB8Z40UH4JkkjP15DBxxPh6VY5TCxRVeQ=";
      };
    };

    endel = {
      name = "Endel";
      url = "https://app.endel.io";
      # Theme-name lookup (e.g. "headphones") is unreliable depending on
      # what resolves the .desktop icon; point straight at the file instead.
      icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark/48x48/devices/headphones.svg";
    };
  };
in
{
  options.cfg.browser.webapps = mkOption {
    internal = true;
    default = [ ];
    description = ''
      Resolved list of enabled webapps, computed above from
      `cfg.browser.webapp.<name>.enable`. Each entry becomes a chromeless
      `chromium --app=<url>` window, its own isolated profile dir
      (cookies/sessions not shared with normal browsing or other webapps),
      and its own `.desktop` entry + taskbar window class
      (modules/chromium.nix).

      Not meant to be set directly by hosts - add a catalog entry above and
      an enable flag under `cfg.browser.webapp` (cfg.nix) instead.

      Requires `cfg.browser.chromium.enable`.
    '';
    type = types.listOf (
      types.submodule (
        { config, ... }:
        {
          options = {
            name = mkOption {
              type = types.str;
              description = "Display name shown in the launcher.";
            };

            url = mkOption {
              type = types.str;
              description = "URL opened in the chromeless app window.";
            };

            id = mkOption {
              type = types.str;
              default = lib.strings.toLower (builtins.replaceStrings [ " " ] [ "-" ] config.name);
              defaultText = literalExpression "slug of `name`";
              description = ''
                Identifier used for the `.desktop` file name, the window
                class (`--class`/`StartupWMClass`) and the isolated profile
                directory (`~/.local/share/webapps/<id>`). Override if the
                auto-generated slug collides or looks wrong.
              '';
            };

            icon = mkOption {
              type = types.nullOr (types.either types.str types.path);
              default = null;
              description = ''
                Icon theme name, or a path to an icon file. Falls back to a
                generic web-browser icon when unset.
              '';
            };

            categories = mkOption {
              type = types.listOf types.str;
              default = [
                "Network"
                "WebBrowser"
              ];
              description = "Desktop entry categories.";
            };
          };
        }
      )
    );
  };

  config.cfg.browser.webapps = lib.mapAttrsToList (_id: w: {
    inherit (w) name url icon;
  }) (lib.filterAttrs (id: _: config.cfg.browser.webapp.${id}.enable) catalog);
}
