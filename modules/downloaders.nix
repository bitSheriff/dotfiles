{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    qbittorrent             # the best and classic torrent
    mullvad-vpn             # avoid suprise visits
    varia                   # simple download manager

  ];

}
