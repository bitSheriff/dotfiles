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
        kdePackages.okular
        stirling-pdf-desktop # pdf editor

        # Diagrams, Brainstorming and more
        drawio

        qalculate-gtk # cli and gui calculator

        # Printers and Scanners
        simple-scan
        ocrmypdf # ocr pdfs in command line
        system-config-printer # GUI to configure CUPS devices

        # Misc
        blanket # background ambient soundscapes for concentration
      ]
      ++ lib.optionals config.cfg.office.libre-office.enable [ pkgs.libreoffice-stable ]
      ++ lib.optionals config.cfg.office.drawing.enable [
        rnote # annotate PDFs and handwritten notes
        # gromit-mpx # draw on desktop
      ]
      ++ lib.optionals config.cfg.office.typora.enable [ typora ]
      ++ lib.optionals config.cfg.office.apostrophe.enable [ apostrophe ]
      ++ lib.optionals config.cfg.office.korganizer.enable [
        kdePackages.korganizer # Calendar and more
        kdePackages.akonadi # needed for korganizer
        kdePackages.akonadi-search # needed for korganizer
        kdePackages.kdepim-runtime
      ]
      ++ lib.optionals config.cfg.office.gnome-calendar.enable [
        gnome-calendar
        evolution-data-server # CalDAV backend for gnome-calendar
        gnome-online-accounts # lets gnome-calendar add CalDAV accounts
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

    # NixOS restricts environment.pathsToLink by default, so Akonadi's resource
    # agents (CalDAV/CardDAV, etc.) from kdepim-runtime never reach
    # /run/current-system/sw and akonadictl only ever lists akonadi_knut_resource.
    environment.pathsToLink = lib.mkIf config.cfg.office.korganizer.enable [
      "/share/akonadi"
      "/lib/qt-6/plugins"
    ];
  };
}
