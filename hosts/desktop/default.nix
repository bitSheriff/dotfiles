{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop-environment.nix
    ../../modules/development.nix
    ../../modules/multimedia.nix
    ../../modules/office.nix
  ];

  networking.hostName = "desktop";

  # Hardware-specific override for Desktop (NVIDIA)
  services.xserver.videoDrivers = ["nvidia"];
  
  system.stateVersion = "25.11"; 
}
