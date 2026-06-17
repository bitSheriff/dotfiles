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
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.halloy = {
      enable = true;
      settings = {
        servers.liberachat = {
          server = "irc.libera.chat";
          channels = [
            "#halloy"
            "#nixos"
          ];

          nickname = "bitSheriff";
          # nick_password_file = "${config.sops.secrets.irc_libera_passwordfile.path}";
        };
      };
    };

    sops.secrets = {
      irc_libera_passwordfile = {
        sopsFile = ../encrypted/secrets.yaml;
        key = "irc/liberachat";
      };

    };
  };
}
