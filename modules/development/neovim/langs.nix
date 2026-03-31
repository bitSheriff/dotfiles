
{ config, pkgs, ... }:
{
  # Language specific Settings, LSPs, ...
  programs.nvf.settings.vim = {

      lsp = {
        enable = true;
        null-ls.enable = true;
      };
      languages = {
          enableTreesitter = true;
          # Languages
          nix.enable = true;
          rust.enable = true;
          bash.enable = true;
          just.enable = true;
          json.enable = true;
          markdown.enable = true;
          python.enable = true;
          yaml.enable = true;
        };
  };
}
