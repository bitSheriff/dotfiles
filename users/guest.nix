{
  lib,
  pkgs,
  activeUsers,
  ...
}:

{
  # Minimal guest user configuration - only if guest is in activeUsers
  users.users.guest = lib.mkIf (lib.elem "guest" activeUsers) {
    isNormalUser = true;
    home = "/home/guest";
    shell = pkgs.zsh;
    # No admin access for guest
    extraGroups = [ ];
  };
}
