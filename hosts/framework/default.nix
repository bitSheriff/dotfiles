{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix   # The generated hardware file
    ../../modules/hyprland.nix
    ../../modules/development.nix
    ../../modules/multimedia.nix
    ../../modules/office.nix
  ];

  system.stateVersion = "25.11";

  networking.hostName = "framework";

  # allow BIOS updates
  services.fwupd.enable = true;

  # Battery Stuff
  services.upower.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;

     #Optional helps save long term battery health
     START_CHARGE_THRESH_BAT1 = 40; # 40 and bellow it starts to charge
     STOP_CHARGE_THRESH_BAT1 = 80; # 80 and above it stops charging

    };
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
