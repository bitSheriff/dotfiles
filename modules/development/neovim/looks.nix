{ config, pkgs, ... }:

{
  programs.nvf = {
    settings.vim = {
      # UI plugins
      statusline.lualine.enable = true; # statusline at the bottom
      filetree.neo-tree.enable = true;

      # Theme
      theme = {
          enable = true;
          name = "dracula";
          style = "dark";
      };
    };
  };
}
