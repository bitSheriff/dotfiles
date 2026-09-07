{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  config = lib.mkIf config.cfg.downloaders.enable {
    environment.systemPackages = with pkgs; [

      qbittorrent # the best and classic torrent
      mullvad-vpn # avoid suprise visits
      varia # simple download manager
      croc # send files to another computer
      yt-dlp # youtube downloader
      inputs.my-flakes.packages.${pkgs.stdenv.hostPlatform.system}.jdownloader2

    ];
  };
}
