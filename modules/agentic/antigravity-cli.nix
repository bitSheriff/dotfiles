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

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.antigravity-cli = {
      enable = true;
      permissions = {
        # allow without asking for permission
        allow = [
          "command(ls*)"
          "command(grep*)"
          "command(tail*)"
          "command(head*)"
        ];

        ask = [ "command(git pull*)" ];
        deny = [ "command(git commit*)" ];
      };

      settings = {
        colorScheme = "tokyo night";
      };
    };

  };
}
