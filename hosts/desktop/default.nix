{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/winmgs/hyprland.nix
    ../../modules/development
    ../../modules/multimedia.nix
    ../../modules/office
    ../../modules/downloaders.nix
  ];

  system.stateVersion = "25.11";

  networking.hostName = "desktop";

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libvdpau-va-gl
    ];
  };
  services.xserver.videoDrivers = ["nvidia"];
}
