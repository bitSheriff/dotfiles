{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

let
  # `pi` itself speaks its own JSON-RPC dialect (`pi --mode rpc`), not ACP, so
  # Zed cannot drive it directly. pi-acp is the adapter that bridges the two:
  # it talks ACP to Zed over stdio and spawns `pi --mode rpc` underneath.
  # It is not in nixpkgs, so npx fetches it on first launch — pin the version
  # so the bridge cannot drift under us. See https://github.com/svkozak/pi-acp
  piAcpVersion = "0.0.33";

  pi-acp = pkgs.writeShellScriptBin "pi-acp" ''
    # nodejs up front for npx; pi-coding-agent appended so the home-manager
    # wrapper (which carries `extraPackages`) still wins if it is on PATH.
    export PATH="${lib.makeBinPath [ pkgs.nodejs ]}:$PATH:${lib.makeBinPath [ pkgs.pi-coding-agent ]}"
    exec npx --yes "pi-acp@${piAcpVersion}" "$@"
  '';
in

{
  imports = [
    ./keymaps.nix
    ./tasks.nix
    ./snippets.nix
    ./lsp.nix
  ];

  # System-wide dev tools
  environment.systemPackages = with pkgs; [
    zed-editor
    nixd
  ];

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.zed-editor = {
      enable = true;
      # Add extensions you might need here
      extensions = [
        "nix"
      ];

      userSettings = {
        # General UI & Editor
        ui_font_size = 16;
        ui_font_family = "Comic Mono";
        buffer_font_size = 16;
        buffer_font_family = "Comic Mono";
        colorize_brackets = true;
        icon_theme = "Catppuccin Mocha";
        show_edit_predictions = true;

        # Vim & Movement
        vim_mode = true;
        relative_line_numbers = "enabled";
        soft_wrap = "editor_width";
        tab_size = 4;
        multi_cursor_modifier = "alt";

        # AI & Session
        session = {
          trust_all_worktrees = true;
        };
        disable_ai = false;
        agent = {
          default_profile = "write";
          default_model = {
            provider = "copilot_chat";
            model = "gpt-4.1";
          };
        };

        agent_servers = {
          # Every entry is an internally tagged enum since Zed 1.16: "custom"
          # for a command we spawn ourselves, "registry" to let Zed fetch and
          # manage the adapter from its ACP registry (`zed: acp registry`).
          # Entries without `type` are what Zed flags as deprecated settings.
          Pi = {
            type = "custom";
            command = lib.getExe pi-acp;
            args = [ ];
            env = {
              # Lets pi resolve Zed's @-mentions instead of receiving them as
              # plain text.
              PI_ACP_ENABLE_EMBEDDED_CONTEXT = "true";
            };
          };
        };

        edit_predictions = {
          mode = "subtle";
          disabled_globs = [
            "**/.env*"
            "**/*.pem"
            "**/*.key"
            "**/*.cert"
            "**/*.crt"
            "**/secrets.yml"
          ];
        };

        # Panels & UI Elements
        collaboration_panel = {
          button = false;
        };
        outline_panel = {
          dock = "right";
        };

        indent_guides = {
          enabled = true;
          coloring = "indent_aware";
        };

        sticky_scroll = {
          enabled = true;
        };

        scrollbar = {
          show = "auto";
          cursors = true;
          git_diff = true;
          search_results = true;
          selected_text = true;
          selected_symbol = true;
          diagnostics = "all";
          axes = {
            horizontal = true;
            vertical = true;
          };
        };

        tabs = {
          file_icons = true;
          git_status = true;
        };

        # Features
        inlay_hints = {
          enabled = true;
          show_type_hints = true;
          show_parameter_hints = true;
          show_other_hints = true;
        };

        autosave = {
          after_delay = {
            milliseconds = 1000;
          };
        };

        # Terminal
        terminal = {
          font_family = "Comic Mono";
          font_size = 13;
          default_height = 320;
          copy_on_select = true;
        };

        # Git
        # Note: Zed has no auto-fetch settings — the `autoFetch*` keys that
        # used to live here are VS Code's and were silently ignored. The
        # on/off switch is `disable_git` (inverted), not `enabled`.
        git = {
          git_gutter = "tracked_files";
          inline_blame = {
            enabled = true;
            # "inline" renders after the line, "status_bar" at the bottom.
            location = "inline";
          };
        };

        # SSH Connections
        # ssh_connections = [
        #   {
        #     host = "";
        #     username = "";
        #     args = [ ];
        #     projects = [
        #       {
        #         paths = [ "" ];
        #       }
        #     ];
        #   }
        # ];

        # Theming
        theme = {
          mode = "dark";
          # light = "One Light";
          dark = "Noctalia Dark";
        };

        # Telemetry
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        # Language Specifics
        # Keys are Zed language names and are case-sensitive: "Nix", not "nix".
        languages = {
          Markdown = {
            format_on_save = "on";
            tab_size = 4;
          };
          Rust = {
            formatter = "language_server";
            format_on_save = "on";
            tab_size = 4;
          };
          Python = {
            formatter = {
              external = {
                command = "black";
                arguments = [ "-" ];
              };
            };
            format_on_save = "on";
            tab_size = 2;
          };
          Nix = {
            formatter = "language_server";
            format_on_save = "on";
            tab_size = 2;
          };
        };

        # LSP Settings
        lsp = {
          rust-analyzer = {
            initialization_options = {
              # rust-analyzer moved the command off `checkOnSave`, which is now
              # just the on/off flag.
              checkOnSave = true;
              check = {
                command = "clippy";
              };
            };
          };
        };

        # File Types — keyed by Zed language name, same as `languages` above.
        file_types = {
          LaTeX = [
            "*.cfg"
            "*.sty"
          ];
          "Shell Script" = [ ".env.*" ];
        };
      };
    };
  };
}
