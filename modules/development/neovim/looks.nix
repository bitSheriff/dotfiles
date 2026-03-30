{ config, pkgs, ... }:

{
  programs.nvf.settings.vim = {
    # UI plugins
    statusline.lualine.enable = true; # statusline at the bottom

    # File tree on the side
    filetree.nvimTree = {
      enable = true;
      setupOpts.git.enable = true;
    };

    dashboard.alpha.enable = true;
    tabline.nvimBufferline.enable = true; # https://github.com/NotAShelf/nvf/blob/main/modules/plugins/tabline/nvim-bufferline/nvim-bufferline.nix
    ui.colorizer.enable = true;       # display RGB values in their color
    ui.noice.enable = true;       # notifications

    # Theme
    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
    };
  };
}
