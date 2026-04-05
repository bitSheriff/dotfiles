{ config, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    opencode
  ];

  home-manager.users.benjamin =
    { config, lib, ... }:
    {

      xdg.configFile = {
        "opencode/opencode.json".source = ./opencode.json;
        "opencode/agents".source = ./agents;
        "opencode/skills".source = ./skills;
      };

    };

}
