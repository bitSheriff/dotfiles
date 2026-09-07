{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
  ];

  config = lib.mkIf config.cfg.gaming.enable {
    environment.systemPackages =
      with pkgs;
      [
        mumble # install voice-chat
      ]
      ++ lib.optionals config.cfg.gaming.heroic.enable [ heroic ]; # for GOG and EPIC GAMES

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.gamemode.enable = true; # for performance mode

    # boot.kernelPackages = pkgs.linuxPackages_zen; # kernel package with ntsync support
    boot.kernelModules = [ "ntsync" ]; # enhance gaming performance for wine/proton games
    boot.kernelParams = [ "ntsync.ntsync_enabled=1" ];

    programs.steam = lib.mkIf config.cfg.gaming.steam.enable {
      enable = true; # install steam
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
}
