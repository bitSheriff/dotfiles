{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  dotfiles_path,
  ...
}:

let
  module_path = "${dotfiles_path}/modules/hyprland";
in
{

  imports = [
    inputs.monique.nixosModules.default
    ../fuzzel.nix
    ../wofi.nix
    ../kdeconnect.nix
    ../noctalia
  ];

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

  # monitor editor for hyprland
  programs.monique.enable = true;

  environment.systemPackages = with pkgs; [
    # Hyprland packages
    hyprcursor
    hyprshot
    brightnessctl # Needed for brightness control keys
    playerctl # Needed for media control keys
    wireplumber # Provides wpctl for volume control
    xwayland # needed for some apps

    # Services
    #dunst                     # notification service
    wl-clipboard # clipboard service
    copyq # clipboard manager
    swappy # screenshot tool
    hyprpolkitagent # polkit agent
    udiskie # automounter
    gsettings-desktop-schemas # for theme settings
    libnotify
    nwg-displays # handle multi-monitor setup

    # Look-and-Feel
    noctalia-shell
    quickshell
    papirus-icon-theme
    adwaita-icon-theme
    adwaita-qt
    lxappearance
    timr-tui
    fastfetch
    starship # Shell prompt
    kitty
    fuzzel # application runner
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
  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      # screenshot annotator
      programs.swappy = {
        enable = true;
        settings = {
          "Config" = {
            save_dir = "$HOME/Pictures/Screenshots";
            save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
          };
        };
      };

      home.sessionVariables = {
        # fix Wayland problem with Rust Tauri
        # https://github.com/tauri-apps/tauri/issues/10702
        WEBKIT_DISABLE_DMABUF_RENDERER = "1";
      };

      xdg.configFile = {
        # use a real symmlink here to enable hot releading of the config (needs absolute path, not relative!!!)
        "hypr".source = config.lib.file.mkOutOfStoreSymlink "${module_path}/hypr";
      };
    };

}
