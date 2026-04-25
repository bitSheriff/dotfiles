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
  hypr_module = "${dotfiles_path}/modules/hyprland";
in
{

  imports = [
  ];

  environment.systemPackages = with pkgs; [
    noctalia-shell
    quickshell
  ];

  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      xdg.configFile = {
        # use a real symmlink here to enable hot releading of the config (needs absolute path, not relative!!!)
        "noctalia".source = config.lib.file.mkOutOfStoreSymlink "${hypr_module}/noctalia";
      };
    };

}
