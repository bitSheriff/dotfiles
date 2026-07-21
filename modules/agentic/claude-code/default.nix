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
        tui = "fullscreen";
        includeCoAuthoredBy = false;
        permissions = {
          defaultMode = "acceptEdits";
          additionalDirectories = [
            "../docs/"
          ];
          allow = [
            "Bash(git diff:*)"
            "Edit"
            "WebFetch"
            "Bash(nix build:*)"
            "Bash(nix run:*)"
            "Bash(nix flake check:*)"
          ];
          ask = [
            "Bash(git push:*)"
            "Bash(git commit:*)"
          ];
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
