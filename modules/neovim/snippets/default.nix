{ config, pkgs, ... }:
{
  programs.nvf.settings.vim.snippets.luasnip = {
    enable = true;
    customSnippets.snipmate = {
      all = [
        {
          trigger = "if";
          body = "if $1 else $2";
        }
      ];

      # #### NIX ####
      nix = [
        {
          trigger = "mkOption";
          body = ''
            mkOption {
              type = $1;
              default = $2;
              description = $3;
              example = $4;
            }
          '';
        }
      ];

      typst = import ./typst.nix;
      markdown = import ./markdown.nix;
      python = import ./python.nix;
    };
  };
}
