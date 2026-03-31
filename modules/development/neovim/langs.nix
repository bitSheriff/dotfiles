{ config, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    neovim
    nixfmt
  ];

  # Language specific Settings, LSPs, ...
  programs.nvf.settings.vim = {

    lsp = {
      enable = true;
      null-ls.enable = true;
      formatOnSave = true;
    };

    languages = {
      enableTreesitter = true;
      # Languages
      nix = {
        enable = true;
        format = {
          enable = true;
          type = "nixfmt";
        };
      };

      python.enable = true;
      rust.enable = true;
      bash.enable = true;
      just.enable = true;
      json.enable = true;
      markdown.enable = true;
      yaml.enable = true;
    };
  };
}
