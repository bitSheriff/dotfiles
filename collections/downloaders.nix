{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  config = lib.mkIf config.cfg.downloaders.enable {
    environment.systemPackages =
      with pkgs;
      [
        mullvad-vpn # avoid suprise visits
        aria2 # best cli to download everything
        varia # simple download manager (uses aria2 under the hoop)
        croc # send files to another computer
        yt-dlp # youtube downloader
      ]
      ++ lib.optionals config.cfg.downloaders.qbittorrent.enable [
        mullvad-vpn # avoid suprise visits
        qbittorrent
      ]
      ++ lib.optionals config.cfg.downloaders.jdownloader.enable [
        inputs.my-flakes.packages.${pkgs.stdenv.hostPlatform.system}.jdownloader2
      ];
  };
}
