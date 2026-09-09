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
    ]
    ++ lib.optionals config.cfg.communication.mumble.enable [
      mumble # low latency voice rooms
    ]
    ++ lib.optionals config.cfg.socials.mastodon.enable [
      toot # TUI for mastodon
      # kdePackages.tokodon # KDE GUI
    ]
    ++ lib.optionals config.cfg.communication.mail.tuta.enable [
      tutanota-desktop # secure encrypted email
    ]
    ++ lib.optionals config.cfg.communication.mail.thunderbird.enable [
      thunderbird
    ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
  };

}
