{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # The generated hardware file
  ];

  networking.hostName = "delos";
  system.stateVersion = "25.11";

  ## Trim SSD
  services.fstrim.enable = true;

  # Battery Stuff
  services.power-profiles-daemon.enable = false; # use tlp instead
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
    # tod.enable = true;
    # tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  # Increase the timeout for the fingerprint reader before it falls back to password (20 min)
  environment.etc."fprintd.conf".text = ''
    [daemon]
    verify_timeout = 1200
  '';

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
    ];
  };

  #####################################
  ###      Host Configuration       ###
  #####################################
  cfg = {
    notes = {
      obsidian.enable = true;
      supernote.enable = true;

    };

    development = {
      enable = true;

      zed.enable = true;
      freecad.enable = true;

      agentic = {
        enable = true;
        pi-coding-agent.enable = true;
        claude-code.enable = true;

      };

      languages = {
        typst.enable = true;
        ccpp.enable = true;
        rust.enable = true;
      };

    };

    browser.qutebrowser.enable = true;
    desktop.hyprland.enable = true;

    office = {
      enable = true;
      libre-office.enable = true;
      marktext.enable = true;

    };

    uni.enable = true;

    communication = {
      signal.enable = true;
      matrix.enable = true;
      mail.tuta.enable = true;
    };

    socials = {
      irc.enable = true;

    };

    multimedia = {
      enable = true;
      ebooks.enable = true;
      eilmeldung.enable = true;
    };

    privacy.enable = true;
  };

}
