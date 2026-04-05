{
  config,
  pkgs,
  username,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    opencode
  ];

  home-manager.users.${username} =
    { config, lib, ... }:
    {

      xdg.configFile = {
        "opencode/opencode.json".source = ./opencode.json;
        "opencode/agents".source = ./agents;
        "opencode/skills".source = ./skills;
      };

    };

}
