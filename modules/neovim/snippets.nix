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

      # #### TYPST ####
      typst = [
        {
          trigger = "h1";
          body = "= ";
        }
        {
          trigger = "h2";
          body = "== ";
        }
        {
          trigger = "h3";
          body = "=== ";
        }
        {
          trigger = "h4";
          body = "==== ";
        }
        {
          trigger = "h5";
          body = "===== ";
        }
      ];
    };
  };
}
