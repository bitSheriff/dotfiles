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
    };
  };
}
