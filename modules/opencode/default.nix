{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    opencode
  ];

  home-manager.users.benjamin =
    {

      xdg.configFile = {
        "opencode/opencode.json".source = ./opencode.json;
        "opencode/agents".source = ./agents;
        "opencode/skills".source = ./skills;
      };

    };

}
