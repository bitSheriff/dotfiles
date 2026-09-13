{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  config = lib.mkIf config.cfg.multimedia.kodi.enable {
    home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
      programs.kodi = {
        enable = true;

        # Plugins are hardcoded on purpose (not exposed via cfg), on top of
        # the optional addons toggled via cfg.multimedia.kodi.*.
        package = pkgs.kodi.withPackages (
          kodiPkgs:
          with kodiPkgs;
          [
            jellyfin
            # youtube (plugin.video.youtube) is dropped in favor of Tubed:
            # it suffers from a long-standing freezing bug (video image
            # freezes, audio keeps playing) tied to inputstream.adaptive/
            # MPEG-DASH playback. Tubed is packaged in ../overlays/kodi-addons
            # since it's not (yet) in nixpkgs' kodiPackages.
            pkgs.kodiPackages.tubed
            joystick # peripheral.joystick: raw joystick/gamepad input (bluetooth controllers)
            bluetooth-manager # manage bluetooth devices from within Kodi
          ]
          ++ lib.optional config.cfg.multimedia.kodi.inputstreamAdaptive.enable inputstream-adaptive
          ++ lib.optional config.cfg.multimedia.kodi.osmcSkin.enable osmc-skin
        );

        sources = {
          video = {
            default = "videos";
            source = [
              {
                name = "videos";
                path = "/home/benjamin/Videos";
                allowsharing = "true";
              }
            ];
          };
        };
      };

      xdg.desktopEntries.kodi = {
        name = "Kodi";
        genericName = "Media Center";
        comment = "Manage and view your media";
        exec = "kodi";
        icon = "kodi";
        terminal = false;
        categories = [
          "AudioVideo"
          "Player"
          "TV"
        ];
      };
    };
  };
}
