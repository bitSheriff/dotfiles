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
          body = "= $1";
        }
        {
          trigger = "h2";
          body = "== $1";
        }
        {
          trigger = "h3";
          body = "=== $1";
        }
        {
          trigger = "h4";
          body = "==== $1";
        }
        {
          trigger = "h5";
          body = "===== $1";
        }
      ];

      # #### Markdown ####
      markdown = [
        {
          trigger = "h1";
          body = "# $1";
        }
        {
          trigger = "h2";
          body = "## $1";
        }
        {
          trigger = "h3";
          body = "### $1";
        }
        {
          trigger = "h4";
          body = "#### $1";
        }
        {
          trigger = "h5";
          body = "#### $1";
        }
        {
          trigger = "callout";
          body = ''
            > [!NOTE]
            > $1
          '';
        }
        {
          trigger = "cmt";
          body = "<!-- $1 -->";
        }
        {
          trigger = "td";
          body = "- [ ] $1";
        }
      ];
    };
  };
}
