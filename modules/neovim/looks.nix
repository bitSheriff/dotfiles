{
  config,
  pkgs,
  lib,
  ...
}:
let
  # leave empty for builtin theme
  colorscheme = "kanagawa";
in
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
    mini.indentscope.enable = true; # show indentation with colored lines
    mini.hipatterns.enable = true; # show color constants in their real color

    # Theme (only taken if no colorscheme plugin is selected)
    theme = lib.mkIf (colorscheme == "") {
      enable = true;
      name = "tokyonight";
      style = "night";
    };

    extraPlugins = {
      lazygit = {
        package = pkgs.vimPlugins.lazygit-nvim;
      };

      ## COLORSCHEME Plugins
      kanagawa = lib.mkIf (colorscheme == "kanagawa") {
        package = pkgs.vimPlugins.kanagawa-nvim;
        setup = "require('kanagawa').load('wave')";
      };
    };
  };
}
