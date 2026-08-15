{ pkgs, lib, ... }:
{
  # hledger-lsp (github:juev/hledger-lsp) — LSP for hledger journal files.
  # The package comes from ../../overlays/hledger-lsp.nix.
  #
  # Files are attached under Neovim's builtin "ledger" filetype rather than the
  # "hledger" filetype the upstream docs suggest, so the tree-sitter ledger
  # parser (which registers itself for "ledger") keeps working. Consequently the
  # semantic token groups below are suffixed ".ledger", not ".hledger".

  programs.nvf.settings.vim = {

    # `.journal` already maps to "ledger" in Neovim's builtin filetype table;
    # `.hledger` and `.prices` do not. timedot gets a filetype of its own so it
    # can be driven by a separate server instance (see hledger_timedot below);
    # timeclock gets one purely for the comment string, as hledger-lsp cannot
    # parse it at all.
    filetype.extension = {
      hledger = "ledger";
      prices = "ledger";
      timedot = "timedot";
      timeclock = "timeclock";
    };

    treesitter.grammars = [
      pkgs.vimPlugins.nvim-treesitter.grammarPlugins.ledger
    ];

    # timedot is close enough to journal syntax (date header, indented account,
    # amount) that the ledger parser highlights it usefully. timeclock is not,
    # so it is left unregistered.
    treesitter.filetypeMappings.ledger = [ "timedot" ];

    lsp.servers.hledger_lsp = {
      enable = true;
      cmd = [ (lib.getExe pkgs.hledger-lsp) ];
      filetypes = [ "ledger" ];

      # root_markers is not usable here, for two reasons: it feeds vim.fs.root,
      # which matches names literally (upstream's suggested "*.journal" never
      # matches anything), and it gives no way to decline attaching. Use the
      # function form of root_dir instead — not calling on_dir skips the server
      # for that buffer. See `:h lsp-root_dir()`.
      root_dir = lib.generators.mkLuaInline ''
        function(bufnr, on_dir)
          local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
          if dir == nil or dir == "" then
            return
          end

          -- hledger-lsp only parses journal syntax. A directory holding
          -- timedot/timeclock files is a time-tracking tree, whose aggregator
          -- tends to be named *.journal (see ../hledger.nix). Attaching there
          -- yields nothing but "included file is not a journal file" errors.
          for name, type in vim.fs.dir(dir) do
            if type == "file" and (name:match("%.timedot$") or name:match("%.timeclock$")) then
              return
            end
          end

          -- Journal-specific markers come first so that e.g.
          -- ~/notes/Journal/_finance is the workspace root, not all of ~/notes.
          on_dir(vim.fs.root(bufnr, { "all.hledger", "hledger.conf", ".git" }))
        end
      '';

      # Read by the server from the "hledger" configuration section.
      # See https://github.com/juev/hledger-lsp/blob/main/docs/configuration.md
      settings.hledger = {
        formatting = {
          indentSize = 4;
          alignAmounts = true;
          amountAlignmentMode = "decimal";
        };

        # Matches the `[check] --strict` in ../hledger.nix.
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

    # A second instance for timedot files. hledger-lsp has no timedot reader,
    # but timedot happens to parse as journal syntax well enough that
    # completion, hover and symbols all work; the one thing it gets wrong is
    # that a timedot posting is single-sided and so never "balances". Hence a
    # separate server rather than reusing hledger_lsp: these settings must not
    # leak into real journals, where an unbalanced transaction is a real error.
    lsp.servers.hledger_timedot = {
      enable = true;
      cmd = [ (lib.getExe pkgs.hledger-lsp) ];
      filetypes = [ "timedot" ];
      root_markers = [
        "all.journal"
        ".git"
      ];

      # init_options, not settings: `features` is only read during Initialize,
      # because the server cannot re-register LSP capabilities afterwards.
      init_options.hledger = {
        diagnostics = {
          # The whole point of this instance.
          unbalancedTransactions = false;
          undeclaredAccounts = false;
          undeclaredCommodities = false;
        };

        features = {
          # timedot files are aligned by `timedot-add` (../hledger.nix) to a
          # fixed 40-column account field. The journal formatter aligns on the
          # decimal point instead, so leaving it on would rewrite these files
          # on every save — formatOnSave is global. Turning the capability off
          # makes vim.lsp.buf.format a no-op here.
          formatting = false;
          # Every timedot posting elides its counterpart, so an "inferred
          # amount" hint would be attached to every single line.
          inlayHints = false;
        };

        cli.path = lib.getExe pkgs.hledger;
      };
    };

    luaConfigPost = ''
      -- hledger-lsp ships custom semantic token types with no default
      -- highlight groups. Re-applied on colorscheme changes, which reset them.
      local function hledger_highlights()
        local links = {
          account = "Identifier",
          commodity = "Type",
          payee = "Function",
          date = "Number",
          amount = "Number",
          directive = "PreProc",
          code = "Special",
          status = "Operator",
        }
        -- Neovim suffixes semantic token groups with the buffer's filetype,
        -- so each filetype an hledger-lsp instance serves needs its own set.
        for _, ft in ipairs({ "ledger", "timedot" }) do
          for token, group in pairs(links) do
            vim.api.nvim_set_hl(0, "@lsp.type." .. token .. "." .. ft, { link = group })
          end
        end
      end

      hledger_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = hledger_highlights })

      -- `o` in normal mode inserts a newline below the LSP layer, so
      -- onTypeFormatting never fires for it. Indent new posting lines in Vim.
      _G.hledger_indentexpr = function()
        local lnum = vim.v.lnum
        if lnum <= 1 then
          return 0
        end
        local prev = vim.fn.getline(lnum - 1)
        -- Transaction header (date), periodic rule (~) or auto rule (=).
        if prev:match("^[%d~=]") then
          return vim.bo.shiftwidth
        end
        -- Continuation of an existing posting.
        if prev:match("^%s+%S") then
          return vim.bo.shiftwidth
        end
        return 0
      end

      -- Tab alignment cannot go through vim.lsp.on_type_formatting: the LSP
      -- response is a TextEdit[] with no cursor position, so the native handler
      -- applies the edit but leaves the cursor behind. Request synchronously
      -- and move the cursor by hand.
      local function hledger_tab()
        local cmp_ok, cmp = pcall(require, "cmp")
        if cmp_ok and cmp.visible() then
          -- <Tab> is nvim-cmp's "next item" binding; let it win while the
          -- completion menu is open.
          return cmp.select_next_item()
        end

        local fallback = function()
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "hledger_lsp" })
        if #clients == 0 then
          return fallback()
        end
        local client = clients[1]

        local pos = vim.api.nvim_win_get_cursor(0)
        local resp = client:request_sync("textDocument/onTypeFormatting", {
          textDocument = vim.lsp.util.make_text_document_params(),
          position = { line = pos[1] - 1, character = pos[2] },
          ch = "\t",
          options = { tabSize = vim.bo.tabstop, insertSpaces = vim.bo.expandtab },
        }, 500, bufnr)

        if not resp or not resp.result or #resp.result == 0 then
          return fallback()
        end

        vim.lsp.util.apply_text_edits(resp.result, bufnr, client.offset_encoding)
        local edit = resp.result[#resp.result]
        vim.api.nvim_win_set_cursor(0, { pos[1], edit.range.start.character + #edit.newText })
      end

      -- Posting indentation applies to timedot too; the <Tab> alignment keymap
      -- does not, since that instance has the formatting capability disabled.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "ledger", "timedot" },
        desc = "hledger: indent new posting lines",
        callback = function(args)
          vim.bo[args.buf].autoindent = true
          vim.bo[args.buf].indentexpr = "v:lua.hledger_indentexpr()"
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "ledger",
        desc = "hledger: align amounts on <Tab>",
        callback = function(args)
          vim.keymap.set("i", "<Tab>", hledger_tab, { buffer = args.buf })
        end,
      })

      -- Neovim 0.12 has native onTypeFormatting but it is off by default;
      -- this is what indents the next posting line when pressing <CR>.
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "hledger: enable onTypeFormatting for hledger_lsp",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "hledger_lsp" then
            vim.lsp.on_type_formatting.enable(true, { client_id = args.data.client_id })
          end
        end,
      })
    '';
  };
}
