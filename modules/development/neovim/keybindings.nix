
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
          action = ":NvimTreeToggl";
          silent = true;
          desc = "Toggle the file explorer on the side";
        }
      ];
  };
}
