{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    mpv
  ];

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    # Colors and fonts are owned by Stylix (modules/stylix) - it writes
    # programs.wofi.style itself, do not set a competing style here.
    programs.wofi = {
      enable = true;
    };
  };

}
