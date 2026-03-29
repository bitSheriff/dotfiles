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

  # Hardware-specific override for Desktop (NVIDIA)
  services.xserver.videoDrivers = ["nvidia"];
}
