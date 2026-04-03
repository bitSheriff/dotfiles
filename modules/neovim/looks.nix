{ config, pkgs, ... }:

{
  programs.nvf.settings.vim = {
    # UI plugins
    statusline.lualine.enable = true; # statusline at the bottom

    notes.todo-comments.enable = true; # highlight comments with TODO

    # File tree on the side
    filetree.nvimTree = {
      enable = true;
      setupOpts.git.enable = true;
    };

    dashboard.alpha.enable = true;
    tabline.nvimBufferline.enable = true;
    ui.colorizer.enable = true; # display RGB values in their color
    ui.noice.enable = true; # notifications
    visuals.rainbow-delimiters.enable = true; # rainbow brackets
    ui.nvim-ufo.enable = true; # show folding levels

    # Theme
    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
    };
  };
}
