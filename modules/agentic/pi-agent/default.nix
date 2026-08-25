{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
let
in
{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.pi-coding-agent = {
      enable = true;
      extraPackages = with pkgs; [ nodejs ];
      settings = {
        theme = "dark";
        enableInstallTelemetry = false;
        quietStartup = true;
        enabledModels = [
          "claude-*"
          "deepseek-*"
        ];
        npmCommand = [ "${lib.getExe' pkgs.nodejs "npm"}" ];
        compaction = {
          enabled = true;
          keepRecentTokens = 20000;
          reserveTokens = 16384;
          defaultThinkingLevel = "medium";
        };
        packages = [
          "npm:pi-mcp-adapter"
          "npm:pi-web-access"
          "npm:@juicesharp/rpiv-ask-user-question"
          "npm:context-mode"
          "npm:pi-claude-auth" # use Claude Code Subscription
        ];
      };
    };

    home.file = {
      ".pi/agent/skills".source = ../_skills;
    };

  };
}
