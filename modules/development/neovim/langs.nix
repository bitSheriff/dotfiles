{ config, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    neovim
    nixfmt
    clang-tools
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
          type = [ "nixfmt" ];
        };
      };

      clang = {
        enable = true;
        lsp.enable = true;
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
