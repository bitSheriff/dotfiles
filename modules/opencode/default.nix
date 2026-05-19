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

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.opencode = {
      enable = true;
      settings = {
        autoupdate = true;
        plugin = [ "opencode-gemini-auth@latest" ];
      };

      tui = {
        keybinds = {
          leader = "alt+b";
        };
        theme = "system";
        diff_style = "auto";
        mouse = true;
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
      "opencode/skills".source = ./skills;
    };

  };

}
