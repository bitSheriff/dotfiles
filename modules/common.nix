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

  # notify about the changes of nixos-rebuild
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
           /run/current-system "$systemConfig"
    '';
  };


  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "de";

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall = rec {
    # needed for KDE Connect
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

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
    # terminal tools
    bash                            # needed only for scripting
    zsh                             # actual shell
    kitty
    vim                             # just as a backup if everythin burns
    comma                           # run nix packages which are not installed
    wget
    curl
    git
    htop
    unzip                           # for .zip
    unrar                           # for .rar
    gnupg
    eza                             # better `ls`
    zoxide                          # smarter `cd` command
    television                      # like fzf but more fancy
    mise                            # like Nix but on project basis (prob not needed anymore if NixOS runs everywhere)
    atuin                           # better shell history
    agenix-cli                      # needed for age to encrypt nix
    rsync                           # nobody uses scp anymore
    tldr                            # better help/man pages for cli programs
    findutils                       # sometimes you need the old find...
    fd                              # better find
    _1password-cli

    # Services and Co
    pciutils
    usbutils
    xdg-utils

    # GUIs
    _1password-gui
    firefox
    ente-auth
    killall
    kdePackages.kate                # simple text editor
  ];

  programs.zsh = {
    enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.kdeconnect.enable = true;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  services.envfs.enable = true;

  services.flatpak.enable = true;
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

 imports = [ inputs.agenix.nixosModules.default ];

 # Tell agenix where to find the decryption key on the server
 age.identityPaths = [ "~/.age" ];
}
