{ config, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    mpv
  ];

  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      programs.mpv = {
        enable = true;

        scripts = with pkgs.mpvScripts; [
          modernz
          thumbfast
        ];

        config = {
          profile = "high-quality";
          keep-open = "yes";
          save-position-on-quit = "yes";
          cursor-autohide = 1000;
          osc = "no";
          osd-level = 0;
        };
      };

      xdg.configFile = {
        "mpv/script-opts/modernz.conf".source = ./script-opts/modernz.conf;
        "mpv/scripts".source = ./scripts;
      };

    };

}
