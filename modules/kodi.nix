{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.cfg.multimedia.kodi.enable {
    environment.systemPackages = [
      (pkgs.kodi.withPackages (
        kodiPkgs: with kodiPkgs; [
          jellyfin
          youtube
        ]
      ))
    ];
  };
}
