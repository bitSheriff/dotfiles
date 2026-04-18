{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{

  imports = [
    ../modules/mpv
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  environment.systemPackages =
    with pkgs;
    [
      # Image & Graphics
      gimp # like photoshop but without selling your soul
      inkscape
      ente-desktop # encrypted photo backup
      qview # minimal image viewer

      # Video & Recording
      vlc

      # Audio
      pavucontrol
      spotify
      audacity # audio editor
      picard # mp3tag editor
    ]

    # Host Specifics
    ++ lib.optionals (config.networking.hostName == "rhodos") [
      fladder
    ]

    # User Specifics - benjamin only
    ++ lib.optionals (lib.elem "benjamin" activeUsers) [
      kew # terminal music player
      musikcube # another terminal music player
    ];
}
