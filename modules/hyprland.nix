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
    noctalia-shell
    dunst               
    kitty               
    wofi                
    wl-clipboard        
    hyprshot
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    starship		# Shell prompt
    fuzzel
    qutebrowser
    quickshell
  ];

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    comic-neue
    comic-mono
    jetbrains-mono
  ];
}
