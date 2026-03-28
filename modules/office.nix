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

    # Communication
    signal-desktop
    cinny-desktop
    localsend

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

  # 3. Scanning Support
  hardware.sane.enable = true;
}
