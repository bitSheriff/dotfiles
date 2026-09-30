{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Colorscheme is owned by Stylix (modules/stylix, nvf target) - do not
  # set programs.nvf.settings.vim.theme or load a colorscheme plugin here,
  # it conflicts.
  programs.nvf.settings.vim = {
    # UI plugins
    statusline.lualine = {
      enable = true; # statusline at the bottom
      # Stylix uses the "mini-base16" nvf plugin (modules/stylix) to avoid
      # a deprecated option, which means it no longer sets lualine's theme
      # itself - restore it here at the current (non-deprecated) path.
      setupOpts.options.theme = "base16";
    };

    # highlight comments with TODO
    notes.todo-comments = {
      enable = true;
      setupOpts = {
        keywords = {
          FIX = {
            icon = " ";
            color = "error";
            # alternative keywords
            alt = [
              "FIXME"
              "BUG"
              "FIXIT"
              "ISSUE"
            ];
          };
          TODO = {
            icon = " ";
            color = "info";
          };
          HACK = {
            icon = " ";
            color = "warning";
          };
          WARN = {
            icon = " ";
            color = "warning";
            alt = [
              "WARNING"
              "XXX"
            ];
          };
          PERF = {
            icon = " ";
            alt = [
              "OPTIM"
              "PERFORMANCE"
              "OPTIMIZE"
            ];
          };
          NOTE = {
            icon = " ";
            color = "hint";
            alt = [ "INFO" ];
          };
          TEST = {
            icon = "⏲ ";
            color = "test";
            alt = [
              "TESTING"
              "PASSED"
              "FAILED"
            ];
          };
        };
      };
    };

    # File tree on the side
    filetree.nvimTree = {
      enable = true;
      setupOpts = {
        git.enable = true;
        filters.exclude = [
          "^.git$"
          "^.venv$"
          "^build$"
        ];
      };
    };

    dashboard.alpha = {
      enable = true;
      theme = "theta";
    };
    tabline.nvimBufferline.enable = true;
    ui.colorizer.enable = true; # display RGB values in their color
    ui.noice.enable = true; # notifications
    visuals.rainbow-delimiters.enable = true; # rainbow brackets
    ui.nvim-ufo.enable = true; # show folding levels
    mini.indentscope.enable = true; # show indentation with colored lines
    mini.hipatterns.enable = true; # show color constants in their real color

    extraPlugins = {
      lazygit = {
        package = pkgs.vimPlugins.lazygit-nvim;
      };
    };
  };
}
