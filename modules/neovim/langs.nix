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
        format.enable = false;
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

    # marksman publishes diagnostics for the *entire* workspace, not just open
    # files. Neovim's handler calls bufadd() for every file it reports
    # (see vim/lsp/diagnostic.lua:244), so a vault with thousands of notes
    # creates thousands of buffers on the main thread and freezes the UI.
    # Only accept marksman diagnostics for files that are already loaded.
    luaConfigRC.marksman-workspace-diagnostics = ''
      do
        local orig = vim.lsp.handlers["textDocument/publishDiagnostics"]
        vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, params, ctx, cfg)
          local client = ctx and ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id)
          if client and client.name == "marksman" and params and params.uri then
            if vim.fn.bufexists(vim.uri_to_fname(params.uri)) == 0 then
              return
            end
          end
          return orig(err, params, ctx, cfg)
        end
      end
    '';

  };
}
