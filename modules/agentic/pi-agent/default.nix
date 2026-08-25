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
        theme = "synthwave-84";
        enableInstallTelemetry = false;
        quietStartup = true;
        npmCommand = [ "${lib.getExe' pkgs.nodejs "npm"}" ];
        defaultProjectTrust = "always"; # always trust new projects
        tuiMode = "fullscreen";
        externalEditor = "zeditor";
        compaction = {
          enabled = true;
          keepRecentTokens = 20000;
          reserveTokens = 16384;
          defaultThinkingLevel = "medium";
        };
        packages = [
          "npm:pi-mcp-adapter" # enable mcp
          "npm:pi-web-access" # enable web search with multiple tools
          "npm:@juicesharp/rpiv-ask-user-question" # ask the user questions
          "npm:context-mode"
          "npm:@juicesharp/rpiv-todo" # work with todos

          # Providers and Login
          "npm:pi-claude-auth" # use Claude Code Subscription (uses claude instance for login, so i guess you need it installed)

          # Themes
          "npm:pi-theme-synthwave-84"
        ];

        # default Provider and Setting
        defaultProvider = "anthropic";
        defaultModel = "claude-sonnet-4-5";
        # other models are not displayed
        enabledModels = [
          "claude-*"
          "deepseek/deepseek-v4*" # DeepSeek models only from deepseek themself
        ];
      };
    };

    home.file = {
      ".pi/agent/skills".source = ../_skills;
      ".pi/agent/extensions".source = ./extensions;
    };

  };
}
