{
  config,
  pkgs,
  lib,
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
    ../modules/screenshots.nix
  ];

  config = lib.mkIf config.cfg.office.enable {
    environment.systemPackages =
      with pkgs;
      [

        # Files & Co
        zathura # Minimalist, keyboard-centric PDF viewer (very Arch-like)
        pdfgrep
        peazip # archive manager
        ouch # universal archiver (zip, rar, ...)
        pdfgrep # search in multiple pdfs

        # Editors & Viewers
        # typora # most beautiful markdown editor
        rnote # PDF annotation and note-taking
        kdePackages.okular
        foliate # ebook reader
        stirling-pdf-desktop # pdf editor
        # yacreader # comic reader

        # Notes & Organization
        # gromit-mpx # draw on desktop

        # Communication
        tutanota-desktop # secure encrypted email
        thunderbird # email

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
      ]
      ++ lib.optionals config.cfg.office.libre-office.enable [ pkgs.libreoffice-stable ];

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
  };
}
