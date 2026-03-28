{ config, pkgs, inputs, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Deduplicate the store automatically to save space
      auto-optimise-store = true;
    };
    # Garbage collection: keeps your drive from filling up with old generations
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Bootloader (Standard Grub or Systemd-boot)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "Europe/Vienna"; 
  i18n.defaultLocale = "en_US.UTF-8";
  
  console.keyMap = "de"; # Or "de" if you prefer

  networking.networkmanager.enable = true;

  users.users.benjamin = {
    isNormalUser = true;
    description = "Benjamin";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" ];
    shell = pkgs.zsh;
  };

  # Only things that should be available to every user/root.
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    pciutils
    usbutils
    htop
    unzip
  ];

  programs.zsh.enable = true; # Necessary to initialize ZSH correctly
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  nixpkgs.config.allowUnfree = true;
}
