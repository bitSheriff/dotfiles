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
        bindings = {
          "l" = "seek 5";
          "h" = "seek -5";
          "k" = "seek 60";
          "j" = "seek -60";
          "]" = "add speed 0.1";
          "[" = "add speed -0.1";
          "}" = "add speed 0.5";
          "{" = "add speed -0.5";
        };
      };

      xdg.configFile = {
        "mpv/script-opts/modernz.conf".source = ./script-opts/modernz.conf;
        "mpv/scripts".source = ./scripts;
      };

    };

}
