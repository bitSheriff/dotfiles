{ config, pkgs, ... }:

{
  imports = [
    ../modules/hledger.nix
    ../modules/notes.nix
    ../modules/zathura.nix
  ];

  environment.systemPackages = with pkgs; [
    typst # sooo much better than LaTeX
    typesetter # minimal typst editor

    # Files & Co
    zathura # Minimalist, keyboard-centric PDF viewer (very Arch-like)
    pdfgrep
    peazip # archive manager
    ouch # universal archiver (zip, rar, ...)
    pdfgrep # search in multiple pdfs

    # Editors & Viewers
    libreoffice-fresh # like beta version
    typora # most beautiful markdown editor
    rnote # PDF annotation and note-taking
    kdePackages.okular
    foliate # ebook reader

    # Notes & Organization
    obsidian
    # gromit-mpx # draw on desktop
    hugo # blog engine

    # Communication
    tutanota-desktop # secure encrypted email
    thunderbird # email
    signal-desktop # chat without Mark Zuckerberg
    cinny-desktop # beautiful matrix chat client

    qalculate-gtk
    copyq

    # Printers and Scanners
    simple-scan

    # Finance
    ledger-live-desktop
  ];

  # Crucial for office work to ensure documents look the same everywhere.
  fonts.packages = with pkgs; [
    corefonts # Microsoft fonts (Arial, Times New Roman)
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

  # Scanning
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.brscan5 ];
    brscan5.enable = true;
  };
  users.users.benjamin.extraGroups = [
    "scanner"
    "lp"
  ];

  # Syncthing
  services.syncthing = {
    enable = true;
    user = "benjamin";
    dataDir = "/home/benjamin/.config/syncthing";
    configDir = "/home/benjamin/.config/syncthing";
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
