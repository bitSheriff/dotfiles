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
    brightnessctl            # Needed for brightness control keys
    playerctl                # Needed for media control keys
    wireplumber              # Provides wpctl for volume control

    # Services
    #dunst                     # notification service
    wl-clipboard
    swappy                   # screenshot tool
    hyprpolkitagent          # polkit agent
    udiskie                  # automounter
    gsettings-desktop-schemas # for theme settings
    libnotify

    # Look-and-Feel
    noctalia-shell
    quickshell
    papirus-icon-theme
    adwaita-icon-theme
    adwaita-qt
    lxappearance
    timr-tui
    fastfetch
    starship		# Shell prompt
    kitty
    wofi                      # application runner
    fuzzel                    # application runner
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    qutebrowser
  ];

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  fonts = {
    packages = with pkgs; [
      comic-neue
      comic-mono
      nerd-fonts.jetbrains-mono
    ];
  
    fontconfig = {
      defaultFonts = {
        serif = [ "Comic Neue" ];
        sansSerif = [ "Comic Neue" ];
        monospace = [ "Comic Mono" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };


  # This ensures environment variables are exported correctly
  services.dbus.enable = true;
}
