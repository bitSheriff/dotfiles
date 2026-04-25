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
  module_path = "${dotfiles_path}/modules/noctalia";
in
{

  imports = [
  ];

  environment.systemPackages = with pkgs; [
    noctalia-shell
    quickshell

    # needed for some plugins
    grim
    slurp
    wl-clipboard
    tesseract
    imagemagick
    zbar
    curl
    translate-shell
    wl-screenrec
    ffmpeg
    gifski
    jq
  ];

  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      xdg.configFile = {
        # use a real symmlink here to enable hot releading of the config (needs absolute path, not relative!!!)
        "noctalia".source = config.lib.file.mkOutOfStoreSymlink "${module_path}/noctalia";
      };
    };

}
