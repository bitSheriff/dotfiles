{ config, pkgs, inputs, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
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

  console.keyMap = "de";

  # Networking
  networking.networkmanager.enable = true;

  # Hardware Support & Services
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.devmon.enable = true;
  boot.supportedFilesystems = [ "ntfs" "exfat" ];
  security.polkit.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # User Configuration
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
    _1password-gui
    _1password-cli
    firefox
    ente-auth
    kitty
    gnupg
    eza
    zoxide
    television
    mise
    atuin
    zsh
    xdg-utils
    killall
    agenix-cli          # needed for age to encrypt nix
    rsync
    bash
    kdePackages.kate                # simple text editor
  ];

  programs.zsh = {
    enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  services.envfs.enable = true;

  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

 imports = [ inputs.agenix.nixosModules.default ];
 # Tell agenix where to find the decryption key on the server
 age.identityPaths = [ "~/.age" ];
}
