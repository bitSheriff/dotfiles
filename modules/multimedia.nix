{ config, pkgs, ... }:

{
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
    gimp # Photo editing
    inkscape # Vector graphics
    loupe # Fast GNOME image viewer
    ente-desktop # encrypted photo backup

    # Video & Recording
    vlc # The "play anything" king
    mpv # High-performance, scriptable player

    # Audio
    spotify # Music streaming
    kew # TUI music player
    pavucontrol # Graphical audio mixer (essential for multi-output)
    audacity # Quick audio editing
  ];

  services.tumbler.enable = true; # Image thumbnails
}
