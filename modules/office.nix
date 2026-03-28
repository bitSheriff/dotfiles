{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    typst
    
    # PDF Handling
    zathura            # Minimalist, keyboard-centric PDF viewer (very Arch-like)
    xournalpp          # PDF annotation and note-taking
    pdf-helper         # CLI tool for merging/splitting PDFs
    
    # Notes & Organization
    obsidian           # Knowledge management
    thunderbird        # Email client
    
    # Communication
    signal-desktop
    cinny-desktop

  ];

  # 2. Typography & Printing
  # Crucial for office work to ensure documents look the same everywhere.
  fonts.packages = with pkgs; [
    corefonts          # Microsoft fonts (Arial, Times New Roman)
    vistafonts         # Calibri, Cambria
    google-fonts       # Roboto, Open Sans, etc.
  ];

  # Enable Printing (CUPS)
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # Helps finding network printers automatically
  };

  # 3. Scanning Support
  hardware.sane.enable = true;
}
