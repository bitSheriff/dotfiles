{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # ./disko.nix
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
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
  services.xserver.videoDrivers = [ "nvidia" ];

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

    gaming = {
      enable = true;
      steam.enable = true;
      heroic.enable = true;

    };

    multimedia = {
      enable = true;
      ebooks.enable = true;
      eilmeldung.enable = true;
    };

    downloaders = {
      enable = true;
      qbittorrent.enable = true;
      jdownloader.enable = true;

    };

    privacy.enable = true;

  };
}
