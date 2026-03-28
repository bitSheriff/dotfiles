{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix   # The generated hardware file
    ../../modules/hyprland.nix
    ../../modules/development.nix
  ];

  networking.hostName = "framework";
  
}
