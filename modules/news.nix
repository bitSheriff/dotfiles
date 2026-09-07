{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
{
  imports = [
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin =
    lib.mkIf (lib.elem "benjamin" activeUsers && config.cfg.multimedia.eilmeldung.enable)
      {
        programs.eilmeldung = {
          enable = true;
          settings = {
            sync_every_minutes = 5;
            mouse_support = true;
            share_targets = [
              "clipboard"
            ];
            startup_commands = [
              "sync"
            ];
            video_enclosure_command = "mpv {url}";

            input_config = {
              mappings = {
                "i" = [
                  "open"
                  "read"
                ];
                "g g" = [ "gotofirst" ];
              };
            };
          };
        };
      };
}
