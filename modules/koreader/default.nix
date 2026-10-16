{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{

  environment.systemPackages =
    with pkgs;
    [
    ]
    ++ lib.optionals config.cfg.multimedia.ebooks.koreader.enable [
      koreader
    ];

  home-manager.users.benjamin =
    lib.mkIf (lib.elem "benjamin" activeUsers && config.cfg.multimedia.ebooks.koreader.enable)
      {
        xdg.configFile = {
          "koreader/plugins/.gitkeep".source = ./plugins/.gitkeep; # just placeholder
        };

      };

}
