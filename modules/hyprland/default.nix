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
    # Hyprland Modules
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprpaper.nix
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
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
    bemoji # needed for emoji selection
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

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      config = lib.mkIf (lib.elem "benjamin" activeUsers) {
        wayland.windowManager.hyprland = {
          enable = true;
          configType = "lua";
          extraLuaFiles = {
            "animations.lua" = {
              autoLoad = true;
              content = ./config/animations.lua;
            };

            "binds.lua" = {
              autoLoad = true;
              content = ./config/binds.lua;
            };

            "env.lua" = {
              autoLoad = true;
              content = ./config/env.lua;
            };

            "monitors.lua" = {
              autoLoad = true;
              content = ./config/monitors.lua;
            };

            "options.lua" = {
              autoLoad = true;
              content = ./config/options.lua;
            };

            "rules.lua" = {
              autoLoad = true;
              content = ./config/rules.lua;
            };

            "startup.lua" = {
              autoLoad = true;
              content = ./config/startup.lua;
            };
          };

          extraConfig = ''
            require("noctalia.noctalia-colors")
          '';
        };

        xdg.configFile = {
          "hypr/config" = {
            source = ./config;
            recursive = true;
          };

          "hypr/noctalia".source =
            config.lib.file.mkOutOfStoreSymlink "${dotfiles_path}/modules/hyprland/noctalia";
        };

        programs.swappy = {
          enable = true;
          settings = {
            "Config" = {
              save_dir = "$HOME/Pictures/Screenshots";
              save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
            };
          };
        };

      };
    };

}
