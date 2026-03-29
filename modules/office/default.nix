{ config, pkgs, ... }:

{
  imports = [
    ./hledger.nix
    ./uni.nix
    ../notes.nix
  ];

  environment.systemPackages = with pkgs; [
    typst                   # sooo much better than LaTeX
    typesetter              # minimal typst editor

    # Files & Co
    zathura                 # Minimalist, keyboard-centric PDF viewer (very Arch-like)
    pdfgrep
    kdePackages.dolphin
    peazip                  # archive manager

    # Editors
    libreoffice-fresh       # like beta version
    typora                  # most beautiful markdown editor
    xournalpp               # PDF annotation and note-taking

    # Notes & Organization
    obsidian
    gromit-mpx              # draw on desktop

    # Communication
    tutanota-desktop        # secure encrypted email
    thunderbird             # email
    signal-desktop          # chat without Mark Zuckerberg
    cinny-desktop           # beautiful matrix chat client
    localsend               # open source AirDrop alternative

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
