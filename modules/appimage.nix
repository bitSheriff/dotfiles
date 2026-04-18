{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
    appimage-run
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Stuff for dynamical-linked executables
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      libuuid
      libusb1
      libkrb5
      libxml2
      glib
      linux-pam
      libGL
      libX11
      libXcursor
      libXi
      libXrandr
      libXrender
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libxcb
      libxkbcommon
      mesa
      libglvnd
      gmp
      ncurses
      udev
    ];
  };
}
