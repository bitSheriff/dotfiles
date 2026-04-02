{ config, pkgs, ... }:

{
  home-manager.users.benjamin.programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        dpi-aware = "no"; # or false
        width = 30;
        font = "Comic Mono:weight=bold:size=14";
        line-height = 20;
        fields = "name,generic,comment,categories,filename,keywords";
        terminal = "kitty -e";
        prompt = "❯   ";
        layer = "overlay";
      };

    };

  };
}
