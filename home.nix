{ config, pkgs, ... }:
{

  home.username = "benjamin";
  home.homeDirectory = "/home/benjamin";

  home.stateVersion = "24.11";

  home.file.".config" = {
    source = ./configuration/.config;
    recursive = true; # This behaves like Stow
  };

  home.file.".zshrc".source = ./configuration/.zshrc;
  home.file.".bashrc".source = ./configuration/.bashrc;
  home.file.".gitconfig".source = ./configuration/.gitconfig;
}
