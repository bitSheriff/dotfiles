{ config, pkgs, ... }:

{
  imports = [
    ./langs.nix
    ./looks.nix
    ./keymaps.nix
    ./snippets.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
  ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = false;
      vimAlias = true;

      clipboard = {
        enable = true;
        registers = "unnamedplus";
      };

      extraPackages = with pkgs; [
        wl-clipboard
      ];

      treesitter.enable = true;
      options = {
        tabstop = 4;
        shiftwidth = 4;
        expandtab = true;
        # Folding
        foldmethod = "expr";
        foldexpr = "v:lua.vim.treesitter.foldexpr()";
        foldlevel = 99; # Start with all folds open
        foldlevelstart = 99;
        foldcolumn = "1";
      };

      # luaConfigPost = ''
      #   vim.api.nvim_create_autocmd("BufReadPost", {
      #     callback = function()
      #       local mark = vim.api.nvim_buf_get_mark(0, '"')
      #       local lcount = vim.api.nvim_buf_line_count(0)
      #       if mark[1] > 0 and mark[1] <= lcount then
      #         pcall(vim.api.nvim_win_set_cursor, 0, mark)
      #       end
      #     end,
      #   })
      # '';

      # plugins which are not availoable in nvf but in nixpkgs
      extraPlugins = with pkgs.vimPlugins; {
        # store the last position in the file and jump there when re-opening
        vim-lastplace = {
          package = vim-lastplace;
        };
      };

      telescope.enable = true;
      autocomplete.nvim-cmp.enable = true;
      git.gitsigns.enable = true;
      autopairs.nvim-autopairs.enable = true;
      comments.comment-nvim.enable = true;

      # move lines up and done
      mini.move = {
        enable = true;
        setupOpts = {
          mappings = {
            left = "<A-left>";
            right = "<A-right>";
            down = "<A-down>";
            up = "<A-up>";

            line_left = "<A-left>";
            line_right = "<A-right>";
            line_down = "<A-down>";
            line_up = "<A-up>";
          };
        };
      };
      # highlight training spaces
      mini.trailspace.enable = true;
      # jump anywhere
      utility.motion.flash-nvim.enable = true;
    };
  };
}
