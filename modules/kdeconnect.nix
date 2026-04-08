{
  config,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username}.services.kdeconnect.enable = true;

  networking.firewall = rec {
    # needed for KDE Connect
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  # enable the service
  systemd.user.services.kdeconnect = {
    description = "KDE Connect daemon";
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/libexec/kdeconnectd";
      Restart = "on-failure";
    };
    wantedBy = [ "default.target" ];
  };
}
