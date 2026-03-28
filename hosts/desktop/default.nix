{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/hyprland.nix
    ../../modules/development.nix
    ../../modules/multimedia.nix
    ../../modules/office.nix
  ];

  system.stateVersion = "25.11"; 

  networking.hostName = "desktop";

  # Hardware-specific override for Desktop (NVIDIA)
  services.xserver.videoDrivers = ["nvidia"];
}
