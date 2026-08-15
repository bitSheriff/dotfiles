{
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  # hledger support in Zed, matching ../neovim/hledger.nix.
  #
  # Unlike Neovim, Zed cannot register a language server from settings alone —
  # a WASM extension is required (zed-industries/zed#52653, closed as not
  # planned). The upstream author publishes one, "hledger"
  # (github:juev/hledger-zed), which supplies the language, the tree-sitter
  # ledger grammar and the hledger-lsp server binding.
  #
  # Caveat: Zed downloads that extension itself at first launch, so it is not
  # Nix-managed. What we *can* pin declaratively is the LSP binary, via
  # lsp.hledger-lsp.binary.path — without it the extension fetches a binary
  # from GitHub releases on its own.

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.zed-editor = {
      extensions = [ "hledger" ];

      userSettings = {
        lsp.hledger-lsp = {
          binary.path = lib.getExe pkgs.hledger-lsp;

          # initialization_options rather than settings: the server gates its
          # LSP capabilities on these during Initialize and cannot re-register
          # them later, so anything under `features` only takes effect here.
          # The server accepts the config with or without the "hledger" wrapper.
          initialization_options.hledger = {
            formatting = {
              indentSize = 4;
              alignAmounts = true;
              amountAlignmentMode = "decimal";
            };

            diagnostics = {
              undeclaredAccounts = true;
              undeclaredCommodities = true;
              unbalancedTransactions = true;
            };

            inlayHints = {
              inferredAmounts = true;
              runningBalances = false;
              costExpansion = false;
            };

            cli.path = lib.getExe pkgs.hledger;
          };
        };

        languages.hledger = {
          tab_size = 4;
          formatter = "language_server";
          format_on_save = "on";
        };
      };
    };
  };
}
