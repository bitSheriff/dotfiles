{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/winmgs/hyprland.nix
    ../../modules/development
    ../../modules/multimedia.nix
    ../../modules/office
  ];

  system.stateVersion = "25.11";

  networking.hostName = "desktop";

  hardware.nvidia.open = true;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
}
