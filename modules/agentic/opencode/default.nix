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

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.opencode = {
      enable = true;

      # pull in the shared MCP servers from `programs.mcp.servers` (../mcp.nix)
      enableMcpIntegration = true;

      # ssettings in `opencode.json`
      settings = {
        plugin = [
          "@simonwjackson/opencode-direnv"
        ];
        formatter = true;
        permission = {
          read = {
            "*" = "allow";
            "*.env" = "ask";
            "*.env.example" = "allow";
          };
          git = {
            "*" = "ask";
            pull = "allow";
            push = "allow";
            commit = "deny";
          };
          nix = {
            check = "allow";
            develop = "allow";
            "build *" = "allow";
            "run *" = "allow";
          };
        };
      };

      # settings in `tui.json`
      tui = {
        keybinds = {
          leader = "alt+b";
        };
        theme = "kanagawa";
        diff_style = "auto";
        mouse = true;
        icons = true;
        sidebar = "left";
      };

      web = {
        enable = true;
        extraArgs = [
          "--port"
          "4096"
        ];
      };

    };

    xdg.configFile = {
      "opencode/agents".source = ./agents;
      "opencode/skills".source = ../skills;
    };

  };

}
