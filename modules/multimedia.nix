{ config, pkgs, ... }:

{

  imports = [
    ./mpv.nix
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # Useful if you ever use Pro-Audio tools like Ardour
  };

  environment.systemPackages = with pkgs; [
    # Image & Graphics
    gimp # like photoshop but withput selling your soul
    inkscape
    ente-desktop # encrypted photo backup
    qview # minimal image viewer

    # Video & Recording
    vlc

    # Audio
    pavucontrol
    spotify
    kew # mp3 player in the console
    audacity # audio editor
    picard # mp3tag editor
  ];

  services.tumbler.enable = true; # Image thumbnails

}
