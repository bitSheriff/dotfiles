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
    kooha # screen recorder
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    services.flameshot = {
      enable = true;
      settings = {
        General = {
          disabledTrayIcon = false;
          showStartupLaunchMessage = false;
          contrastOpacity = 0;
        };
      };
    };
  };
}
