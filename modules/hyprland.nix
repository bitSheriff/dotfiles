{ config, pkgs, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };


  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd hyprland";
        user = "greeter";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # Hyprland packages
    hyprcursor
    hyprshot

    # Services
    dunst                     # notification service
    wl-clipboard

    # Look-and-Feel
    noctalia-shell
    quickshell
    papirus-icon-theme
    adwaita-qt
    lxappearance
    timr-tui
    starship		# Shell prompt
    kitty
    wofi                      # application runner
    fuzzel                    # application runner
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    qutebrowser
    kdePackages.dolphin
  ];

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    comic-neue
    comic-mono
    nerd-fonts.jetbrains-mono
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };


  # This ensures environment variables are exported correctly
  services.dbus.enable = true;
}
