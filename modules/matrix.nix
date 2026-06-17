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
    cinny-desktop # beautiful matrix chat client
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.iamb = {
      enable = true;
      settings = { };
    };

    sops.secrets = {
      iamb_config = {
        sopsFile = ../encrypted/iamb_config.txt;
        format = "binary";
        path = "${config.users.users.benjamin.home}/.config/iamb/config.toml";
      };

    };
  };
}
