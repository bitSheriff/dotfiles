{ config, pkgs, ... }:

{
  # 1. Enable Hyprland (NixOS module handles the portal and session)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Wayland/NVIDIA Environment Variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # 2. Display Manager (Greetd is lightweight and Wayland-native)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd hyprland";
        user = "greeter";
      };
    };
  };

  # 3. GUI System Packages
  environment.systemPackages = with pkgs; [
    waybar              # Status bar
    swww                # Wallpaper daemon
    dunst               # Notifications
    kitty               # Terminal emulator
    wofi                # App launcher
    wl-clipboard        # Clipboard manager
  ];

  # 4. Enable Sound and Fonts for the Desktop
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    nerdfonts
    noto-fonts-emoji
  ];
}
