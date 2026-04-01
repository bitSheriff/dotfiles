{
  config,
  pkgs,
  lib,
  ...
}:

let
  dotfiles = "/home/benjamin/code/dotfiles/configuration";
in
{
  home-manager.users.benjamin =
    { config, ... }:
    {
      xdg.configFile."zed/snippets".source =
        config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/zed/snippets";
    };
}
