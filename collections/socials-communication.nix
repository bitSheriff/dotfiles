{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:
let
in
{
  imports = [
    ./../modules/irc.nix
  ];

  environment.systemPackages =
    with pkgs;
    [
    ]
    ++ lib.optionals config.cfg.communication.signal.enable [
      signal-desktop # chat without Mark Zuckerberg
      signal-cli
      siggy # terminal-based Signal client (via overlay)
    ]
    ++ lib.optionals config.cfg.communication.matrix.enable [
      cinny-desktop # beautiful matrix chat client
    ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
  };

}
