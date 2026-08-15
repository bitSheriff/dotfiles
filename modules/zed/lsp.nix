{
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  # Language server configuration for Zed. One block per LSP; the general
  # editor settings live in ./default.nix.
  #
  # Note that Zed cannot register a language server from settings alone — a
  # WASM extension is required (zed-industries/zed#52653, closed as not
  # planned). So each server here needs a matching entry in `extensions`, and
  # Zed downloads that extension itself on first launch; it is not Nix-managed.
  # What we can pin declaratively is the server binary, via
  # `lsp.<name>.binary.path`.

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.zed-editor = {
      extensions = [
        # Supplies the hledger language, the tree-sitter ledger grammar and the
        # hledger-lsp binding. See https://github.com/juev/hledger-zed
        "hledger"
      ];

      userSettings = {
        # hledger — see ../neovim/hledger.nix for the Neovim equivalent, and
        # ../../overlays/hledger-lsp.nix for the package.
        lsp.hledger-lsp = {
          # Without this the extension fetches its own binary from GitHub
          # releases; pointing at the store path reuses the one Nix built.
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

        # The extension claims .journal/.hledger/.ledger but not .timedot, so
        # timedot files would otherwise open as plain text. Mapping them onto
        # the hledger language buys syntax highlighting; the language server is
        # switched off for that tree by ~/notes/Journal/_time/.zed/settings.json,
        # which is what keeps the balance-check noise away. Unlike Neovim, Zed
        # cannot run a second server instance with per-directory settings.
        file_types.hledger = [ "*.timedot" ];
      };
    };
  };
}
