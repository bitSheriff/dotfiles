{ config, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    neovim
    nixfmt
    clang
    clang-tools
    nixd
    shfmt # format shell scripts
    marksman # markdown LSP
    prettier # formatter for different languages
    tinymist # LSP for Typst
  ];

  # Language specific Settings, LSPs, ...
  programs.nvf.settings.vim = {

    lsp = {
      enable = true;
      formatOnSave = true;

      # Nix Language Server
      servers.nixd = {
        enable = true;
        server = "nixd";
        init_options = {
          nixpkgs.expr = "import <nixpkgs> { }";
          formatting.command = [ "nixfmt" ];
        };
      };

      servers.clang = {
        enable = true;
      };
    };

    languages = {
      enableTreesitter = true;
      # Languages
      nix = {
        enable = true;
        treesitter.enable = true;
        format = {
          enable = true;
          type = [ "nixfmt" ];
        };
      };

      clang = {
        enable = true;
        lsp.enable = true;
      };

      bash = {
        enable = true;
        lsp.enable = true;
        format.enable = true; # Uses shfmt
      };

      python.enable = true;
      rust.enable = true;
      just.enable = true;
      json.enable = true;

      markdown = {
        enable = true;
        lsp.enable = true;
        format.enable = true;
        # render markdown
        extensions.render-markdown-nvim.enable = true;
      };

      yaml = {
        enable = true;
        lsp.enable = true;
      };

      typst = {
        enable = true;
        lsp.enable = true;
      };
    };
  };
}
