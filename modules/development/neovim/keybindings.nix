
{ config, pkgs, ... }:
{
  programs.nvf = {
      settings.vim.keymaps = [
        {
          key = "<leader>wq";
          mode = ["n"];
          action = ":wq<CR>";
          silent = true;
          desc = "Save file and quit";
        }
        {
          key = "<leader>n";
          mode = ["n"];
          action = ":NvimTreeToggle<CR>";
          silent = true;
          desc = "Toggle the file explorer on the side";
        }
        {
          key = "<c-q>";
          mode = ["n"];
          action = ":qa<CR>";
          silent = true;
          desc = "Exit";
        }
        {
          key = "<c-s>";
          mode = ["n"];
          action = ":w<CR>";
          silent = true;
          desc = "Save current file";
        }
        {
          key = "<c-a>";
          mode = ["n"];
          action = "ggVG";
          silent = true;
          desc = "Select All";
        }
        {
          key = "<Tab>";
          mode = ["n"];
          action = ":BufferLineCycleNext<CR>";
          silent = true;
          desc = "Next buffer";
        }
        {
          key = "<S-Tab>";
          mode = ["n"];
          action = ":BufferLineCyclePrev<CR>";
          silent = true;
          desc = "Previous buffer";
        }
        {
          key = "<leader>f";
          mode = ["n"];
          action = "function() require('flash').jump() end";
          silent = true;
          desc = "Flash";
        }
      ];
  };
}
