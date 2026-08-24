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
        npmCommand = [ "${lib.getExe' pkgs.nodejs "npm"}" ];
        compaction = {
          enabled = true;
          keepRecentTokens = 20000;
          reserveTokens = 16384;
          defaultThinkingLevel = "medium";
        };
        defaultModel = "deepseek/deepseek-v4-flash";
        packages = [
          "npm:pi-mcp-adapter"
          "npm:pi-web-access"
          "npm:@juicesharp/rpiv-ask-user-question"
          "npm:context-mode"
        ];
      };
    };
  };
}
