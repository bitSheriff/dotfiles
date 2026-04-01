{ pkgs, config, ... }:
{
  imports = [
  ];

  options = {
  };

  config = {
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32bit = true;
    };

    programs.gamemode.enable = true; # for performance mode
    boot.kernel = [ "ntsync" ]; # enhance gaming performance

    programs.steam = {
      enable = true; # install steam
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    environment.systemPackages = with pkgs; [
      # mumble # install voice-chat
    ];
  };
}
