{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix   # The generated hardware file
    ../../modules/hyprland.nix
    ../../modules/development.nix
  ];

  system.stateVersion = "25.11"; 

  networking.hostName = "framework";

  # allow BIOS updates
  services.fwupd.enable = true;
  

  services.tlp = {
    enable = true;
  };

  # Fingerprint Reader
  services.fprintd = {
    enable = true;
    tod = { 
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix; # Goodix driver module
    };
  };
}
