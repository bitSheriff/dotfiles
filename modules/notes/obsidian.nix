{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
{

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.obsidian = {
      enable = true;
      cli.enable = true;

      # do not use static defined vaults, just an example for the future maybe
      vaults.notes = {
        enable = false;
        target = "notes"; # path from the HOME
      };
    };

  };
}
