{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "rhodos";
  system.stateVersion = "25.11";

  ## Trim SSD
  services.fstrim.enable = true;

  hardware.nvidia = {
    open = false; # open driver or closed-source ones
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [ nvidia-vaapi-driver ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  services.xserver.videoDrivers = [ "nvidia" ];
}
