{
  config, # Top-level NixOS config
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
let
  # ATN ships no nixpkgs package; grab the xpi directly like AMO's
  # /latest/ redirect. Versions pinned via sha256 so updates are explicit.
  buildAtnAddon =
    {
      pname,
      version,
      addonId,
      slug,
      sha256,
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl {
        url = "https://addons.thunderbird.net/thunderbird/downloads/latest/${slug}/addon-${slug}-latest.xpi";
        inherit sha256;
      };
      preferLocalBuild = true;
      # Layout home-manager's programs.thunderbird.profiles.<p>.extensions expects:
      # share/mozilla/extensions/{ec8030f7-...}/<addonId>.xpi (Gecko toolkit app GUID,
      # shared by Firefox and Thunderbird extension loading).
      buildCommand = ''
        dest="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dest"
        install -D -m644 "$src" "$dest/${addonId}.xpi"
      '';
    };

  tutaMail = buildAtnAddon {
    pname = "tuta-mail";
    version = "1.0.0";
    addonId = "@tutamail.thunderbird";
    slug = "tuta-mail";
    sha256 = "d991c2686e681a702ee2a70810dd7cd39a27c24c8d5d9fe08c43e95882ee4a09";
  };

  tutaCalendar = buildAtnAddon {
    pname = "tuta-calendar";
    version = "1.0.0";
    addonId = "@tutacalendar.thunderbird";
    slug = "tuta-calendar";
    sha256 = "f9a17b7d2b43cc1628f01a2eb443ab7f25ad8ecfb2f53985faa15d8f9a6c326e";
  };

  # No stylix.targets.thunderbird yet (nix-community/stylix#2529, unmerged)
  stylixThemeId = "stylix-theme@thunderbird";

  stylixTheme =
    let
      c = config.lib.stylix.colors.withHashtag;
      manifest = {
        manifest_version = 2;
        name = "Stylix";
        version = "1.0.1";
        description = "Thunderbird theme generated from the system Stylix base16 palette.";
        browser_specific_settings.gecko = {
          id = stylixThemeId;
          strict_min_version = "115.0";
        };
        theme.colors = {
          frame = c.base01;
          frame_inactive = c.base00;
          tab_background_text = c.base05;
          tab_background_separator = c.base0D;
          tab_selected = c.base00;
          tab_text = c.base05;
          tab_line = c.base0D;
          tab_loading = c.base05;
          toolbar = c.base00;
          toolbar_text = c.base05;
          toolbar_field = c.base02;
          toolbar_field_text = c.base05;
          toolbar_field_border = c.base00;
          toolbar_field_focus = c.base00;
          toolbar_field_text_focus = c.base05;
          toolbar_field_border_focus = c.base0D;
          toolbar_field_highlight = c.base0D;
          toolbar_field_highlight_text = c.base00;
          toolbar_top_separator = c.base00;
          toolbar_bottom_separator = c.base00;
          toolbar_vertical_separator = c.base0D;
          icons = c.base05;
          icons_attention = c.base0D;
          button_background_hover = c.base02;
          button_background_active = c.base04;
          popup = c.base00;
          popup_text = c.base05;
          popup_border = c.base0D;
          popup_highlight = c.base04;
          popup_highlight_text = c.base05;
          sidebar = c.base00;
          sidebar_text = c.base05;
          sidebar_border = c.base0D;
          sidebar_highlight = c.base0D;
          sidebar_highlight_text = c.base05;
        };
      };
    in
    pkgs.runCommand "thunderbird-stylix-theme-1.0.1" { } ''
      dest="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${stylixThemeId}"
      mkdir -p "$dest"
      cp ${pkgs.writeText "manifest.json" (builtins.toJSON manifest)} "$dest/manifest.json"
    '';
in
{
  imports = [ ];

  environment.systemPackages = with pkgs; [ ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin =
    lib.mkIf (lib.elem "benjamin" activeUsers && config.cfg.communication.mail.thunderbird.enable)
      (
        { config, osConfig, ... }:
        {
          programs.thunderbird = {
            enable = true;
            package = pkgs.thunderbird;

            profiles.default = {
              isDefault = true;
              withExternalGnupg = true; # OpenPGP delegates to system gpg-agent instead of the bundled RNP
              extensions = [
                stylixTheme
              ]
              ++ lib.optionals osConfig.cfg.communication.mail.tuta.enable [
                tutaMail
                tutaCalendar
              ];
              settings = {
                "mail.openpgp.alternative_gpg_path" = "${config.programs.gpg.package}/bin/gpg";
                "xpinstall.signatures.required" = false;
                "extensions.autoDisableScopes" = 0;
                "extensions.activeThemeID" = stylixThemeId;
              };
            };
          };
        }
      );
}
