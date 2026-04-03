{ pkgs, config, ... }:
{
  imports = [
  ];

  options = {
  };

  config = {

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.gamemode.enable = true; # for performance mode

    boot.kernelPackages = pkgs.linuxPackages_zen; # kernel package with ntsync support
    boot.kernelModules = [ "ntsync" ]; # enhance gaming performance for wine/proton games
    boot.kernelParams = [ "ntsync.ntsync_enabled=1" ];

    programs.steam = {
      enable = true; # install steam
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    environment.systemPackages = with pkgs; [
      mumble # install voice-chat
    ];
  };
}
