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
        git = {
          commit = false;
          push = false;
        };
        privacy.mask_secrets = true;
        rg.extraArgs = [ "--hidden" ];
        nix = {
          sandbox = true;
          formatter = "nixfmt";
          auto_direnv = true;
        };
      };

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
      "opencode/skills".source = ./skills;
    };

  };

}
