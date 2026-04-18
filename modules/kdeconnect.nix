{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    services.kdeconnect.enable = true;
  };
}
