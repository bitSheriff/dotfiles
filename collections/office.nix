{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../modules/hledger
    ../modules/notes
    ../modules/zathura.nix
    ../modules/syncthing.nix
    ../modules/supernote.nix
    ../modules/marktext.nix
  ];

  environment.systemPackages =
    with pkgs;
    [
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
      stirling-pdf-desktop # pdf editor
      # yacreader # comic reader

      # Notes & Organization
      obsidian
      # gromit-mpx # draw on desktop

      # Communication
      tutanota-desktop # secure encrypted email
      thunderbird # email
      signal-desktop # chat without Mark Zuckerberg
      cinny-desktop # beautiful matrix chat client

      kdePackages.korganizer # Calendar and more
      kdePackages.akonadi # needed for korganizer
      kdePackages.akonadi-search # needed for korganizer
      kdePackages.kdepim-runtime

      qalculate-gtk # cli and gui calculator

      # Printers and Scanners
      simple-scan
      ocrmypdf # ocr pdfs in command line
      system-config-printer # GUI to configure CUPS devices

      # Finance
      ledger-live-desktop

      # Misc
      blanket # background ambient soundscapes for concentration

    ]
    # Host Specifics
    ++ lib.optionals (config.networking.hostName == "rhodos") [
      # Building Stuff
      freecad
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

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
