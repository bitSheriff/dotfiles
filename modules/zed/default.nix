{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  imports = [
    ./keymaps.nix
    ./tasks.nix
    ./snippets.nix
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
              gemini-custom = {
                type = "custom";
                comand = "gemini";
              };

              gemini = {
                ignore_system_version = false;
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
            notification_panel = {
              dock = "left";
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
            git = {
              enabled = true;
              autoFetch = true;
              autoFetchInterval = 300;
              autoFetchOnFocus = true;
              autoFetchOnWindowChange = true;
              autoFetchOnBuild = true;
              autoFetchOnBuildEvents = [
                "build"
                "run"
                "debug"
              ];
              autoFetchOnBuildEventsDelay = 1500;
              autoFetchOnBuildDelay = 1500;
              git_gutter = "tracked_files";
              inline_blame = {
                enabled = true;
                position = "right";
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
              light = "One Light";
              dark = "Wallust";
            };

            # Telemetry
            telemetry = {
              diagnostics = false;
              metrics = false;
            };

            # Language Specifics
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
              # Keeping your Nix settings from before
              nix = {
                formatter = "language_server";
                format_on_save = "on";
                tab_size = 2;
              };
            };

            # LSP Settings
            lsp = {
              rust-analyzer = {
                initialization_options = {
                  checkOnSave = {
                    command = "clippy";
                  };
                };
              };
            };

            # File Types
            file_types = {
              latex = [
                "*.cfg"
                "*.sty"
              ];
              dotnev = [ ".env.*" ]; # Preserved typo from original "dotnev"
            };
          };
        };
      };
}
