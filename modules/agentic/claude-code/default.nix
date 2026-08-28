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
      rulesDir = ./rules;
      commandsDir = ./commands;
      agentsDir = ../_agents;
      # pull in the shared MCP servers from `programs.mcp.servers` (../mcp.nix)
      enableMcpIntegration = true;

      skills = {
        sort-ebooks = ../_skills/sort-ebooks;
        hledger = ../_skills/hledger;

        # Obsidian
        obsidian-bases = ../_skills/obsidian-bases;
        obsidian-cli = ../_skills/obsidian-cli;
        obsidian-markdown = ../_skills/obsidian-markdown;
        json-canvas = ../_skills/json-canvas;
      };

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
            "Edit"
            "WebFetch"
            "Bash(echo \"exit: $?\")" # print last exit code

            # Git Stuff
            "Bash(git diff *)"
            "Bash(git lfs *)"

            # Nix Stuff
            "Bash(nix build *)"
            "Bash(nix run *)"
            "Bash(nix flake check *)"
            "Bash(nix --version)"
            "Bash(nix develop *)"
            "Bash(nix fmt *)"
            "Bash(nix log *)"

            # MCP, allow all MCPs which were configured with HomeManager
            "mcp__plugin_hm_hledger"
            "mcp__plugin_hm_nixos"
          ];
          ask = [
            "Bash(git push:*)"
            "Bash(git commit:*)"
            "Bash(curl:*)"
          ];
          deny = [
            "Read(./.env)"
            "Read(./secrets/**)"
          ];
        };
      };
    };

  };
}
