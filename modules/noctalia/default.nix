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
    cliphist
    curl
    ffmpeg
    gifski
    grim
    imagemagick
    jq
    slurp
    tesseract
    translate-shell
    wl-clipboard
    wl-screenrec
    zbar
  ];

  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      config = lib.mkIf (lib.elem "benjamin" activeUsers) {
        xdg.configFile = {
          # use a real symmlink here to enable hot releading of the config (needs absolute path, not relative!!!)
          "noctalia".source = config.lib.file.mkOutOfStoreSymlink "${module_path}/noctalia";
        };
      };
    };

}
