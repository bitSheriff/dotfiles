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

  environment.systemPackages = with pkgs; [
    claude-code
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.claude-code = {
      enable = true;
      skills = {

      };
      rulesDir = ./rules;
      commandsDir = ./commands;
      agentsDir = ./agents;

      settings = {
        theme = "dark";
        includeCoAuthoredBy = false;
        permissions = {
          additionalDirectories = [
            "../docs/"
          ];
          allow = [
            "Bash(git diff:*)"
            "Edit"
            "WebFetch"
          ];
          ask = [
            "Bash(git push:*)"
          ];
          defaultMode = "acceptEdits";
          deny = [
            "Bash(curl:*)"
            "Read(./.env)"
            "Read(./secrets/**)"
          ];
        };
      };
    };

  };
}
