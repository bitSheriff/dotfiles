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

    luaConfigRC.markdown-logic = ''
            -- Toggle Checkboxes
      vim.keymap.set('n', '<leader>tt', function()
            local line = vim.api.nvim_get_current_line()
            local new_line

            if line:match("%[ %]") then
              new_line = line:gsub("%[ %]", "[x]", 1)
            elseif line:match("%[x%]") then
              new_line = line:gsub("%[x%]", "[ ]", 1)
            -- Improved pattern: Find the bullet (*, -, or +) and any following space
            elseif line:match("^%s*[%*%-%+]%s*") then
              new_line = line:gsub("^%s*([%*%-%+])%s*", "%1 [ ] ", 1)
            end

            if new_line then
              vim.api.nvim_set_current_line(new_line)
            end
          end, { desc = "Toggle Markdown Todo" })
    '';

  };
}
