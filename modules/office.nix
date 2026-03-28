{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    typst

    # Files & Co
    zathura            # Minimalist, keyboard-centric PDF viewer (very Arch-like)
    xournalpp          # PDF annotation and note-taking
    pdfgrep
    kdePackages.dolphin

    # Notes & Organization
    obsidian
    thunderbird
    anki
    hledger
    gromit-mpx          # draw on desktop

    # Communication
    signal-desktop
    cinny-desktop
    localsend
    #iamb                # matrix chat in the terminal

    qalculate-gtk
    copyq

  ];

  # Crucial for office work to ensure documents look the same everywhere.
  fonts.packages = with pkgs; [
    corefonts          # Microsoft fonts (Arial, Times New Roman)
    #google-fonts       # Roboto, Open Sans, etc.
    comic-neue
    nerd-fonts.jetbrains-mono
    fira-code
    fira-code-symbols
  ];

  # Enable Printing (CUPS)
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # Helps finding network printers automatically
  };

  # Printing
  hardware.sane.enable = true;

  # Syncthing
  services.syncthing = {
      enable = true;
       user = "benjamin";
       dataDir = "/home/benjamin/.config/syncthing";
       configDir = "/home/benjamin/.config/syncthing";
  };
}
