{
  config,
  lib,
  pkgs,
  ...
}:

# Central place to declare toggleable "features" for this flake.
#
with lib;

let
in
{
  imports = [
    ./modules/common.nix
    ./modules/hyprland

    # Collections
    ./collections/development.nix
    ./collections/downloaders.nix
    ./collections/gaming.nix
    ./collections/multimedia.nix
    ./collections/office.nix
    ./collections/privacy.nix
    ./collections/uni.nix
    ./collections/socials-communication.nix
  ];

  options.cfg = {

    #################
    ## Development ##
    #################
    development = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Development tooling: editors, terminals, languages, vscode, direnv, git, etc.";
      };

      git = {

        tuis = {
          lazygit = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Lazygit";
            };
          };
        };

        guis = {
          gitte = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable Gitte";
            };
          };

          smartgit = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable SmartGit";
            };
          };

        };

      };

      # Virtual Machines & Co
      virtualization = {
        vm = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable virtual machines";
          };
        };

        docker = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Docker";
          };
        };
      };

      zed = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install and configure the Zed editor (modules/zed).";
        };
      };

      vscode = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install vscode";
        };
      };

      freecad = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install FreeCAD";
        };
      };

      embedded = {
        platformio = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install and enable PlatformIO";
          };
        };
      };

      agentic = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "General agentic-coding tooling: shared MCP server registry (nixos-mcp, hledger-mcp), opencode, herdr. Individual agent CLIs have their own enable flags.";
        };

        pi-coding-agent = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install and configure pi-coding-agent (modules/agentic/pi-agent).";
          };
        };

        claude-code = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install and configure Claude Code (modules/agentic/claude-code).";
          };
        };

        antigravity = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install and configure the Antigravity CLI (modules/agentic/antigravity.nix).";
          };
        };

        # Locally hosted models (modules/agentic/localAI). When disabled, no
        # local backend is installed and no local provider is configured in
        # any agent (pi, opencode, ...).
        localAI = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Run large language models locally and expose them to the agentic tooling.";
          };

          backend = mkOption {
            type = types.enum [
              "ollama"
              "lmstudio"
            ];
            default = "ollama";
            description = ''
              Which local inference server to use.

              `ollama` is a declarative systemd service: models come from
              `localAI.models` and are pulled on activation.

              `lmstudio` is an unfree GUI application. It is only installed
              here; the server, the loaded model and its context length are
              managed inside the app and cannot be declared.
            '';
          };

          host = mkOption {
            type = types.str;
            default = "localhost";
            description = ''
              Host serving the OpenAI-compatible API. Point this at another
              machine to use its GPU (that host needs to listen on more than
              loopback, see `localAI.openFirewall`).
            '';
          };

          port = mkOption {
            type = types.port;
            default = if config.cfg.development.agentic.localAI.backend == "ollama" then 11434 else 1234;
            defaultText = literalExpression "11434 for ollama, 1234 for lmstudio";
            description = "Port of the OpenAI-compatible API.";
          };

          openFirewall = mkOption {
            type = types.bool;
            default = false;
            description = "Serve the API on the local network instead of loopback only. Only honoured by the ollama backend.";
          };

          models = mkOption {
            default = [ ];
            description = ''
              Models to make available on this host. Empty means none.

              With the ollama backend these are pulled on activation
              (`services.ollama.loadModels`). With lmstudio you still have to
              download them in the GUI; the entries here only tell the agents
              which models to offer.
            '';
            example = literalExpression ''
              [
                {
                  id = "qwen3:27b";
                  name = "Qwen3 27B (local)";
                  reasoning = true;
                  contextWindow = 32768;
                }
              ]
            '';
            type = types.listOf (
              types.submodule {
                options = {
                  id = mkOption {
                    type = types.str;
                    description = ''
                      Model id exactly as the backend serves it. Verify with
                      `ollama list` or `curl http://localhost:1234/v1/models`.
                    '';
                  };

                  name = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Human readable label. Defaults to `id`.";
                  };

                  contextWindow = mkOption {
                    type = types.int;
                    default = 32768;
                    description = ''
                      Context window in tokens. Must match what the model is
                      actually LOADED with, not what it could theoretically do -
                      the agent will happily send more and the request fails.
                    '';
                  };

                  maxTokens = mkOption {
                    type = types.int;
                    default = 8192;
                    description = "Maximum output tokens per response.";
                  };

                  reasoning = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Whether the model emits thinking/reasoning content.";
                  };

                  extraConfig = mkOption {
                    type = types.attrs;
                    default = { };
                    description = ''
                      Merged verbatim into the model definition handed to the
                      agent, for per-model knobs that have no option here
                      (`thinkingLevelMap`, `compat`, `samplingParams`, ...).
                    '';
                    example = literalExpression "{ thinkingLevelMap.off = null; }";
                  };
                };
              }
            );
          };
        };
      };

      android = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable basic Android Development/Debugging";
        };
      };

      languages = {
        latex = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install LaTeX";
          };

          package = mkOption {
            type = types.package;
            default = pkgs.texliveMedium;
            defaultText = literalExpression "pkgs.texliveMedium";
            description = "The LaTeX package/scheme to install.";
          };
        };

        typst = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install Typst";
          };
        };

        rust = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install Rust";
          };
        };

        python = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install Python";
          };
        };

        ccpp = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install C/C++";
          };
        };

        markdown = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Install Markdown tools";
          };

        };
      };
    };

    ################
    ## Multimedia ##
    ################
    multimedia = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Audio/video/image apps: pipewire, mpv, mpd, image viewers, music players, etc.";
      };

      mpd = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable MPD (Music Player Daemon) + mpc/rmpc clients.";
        };
      };

      eilmeldung = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the TUI news reader";
        };
      };

      newsflash = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the GUI news reader";
        };
      };

      ebooks = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable ebook reading";
        };

        koreader = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable KOReader";
          };
        };
      };

      comics = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable comic books reading";
        };
      };

      podcasts = {
        kasts = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install KDE Kasts (supports gpodder sync)";
          };
        };
      };

      kodi = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install Kodi media center (modules/kodi.nix) with the jellyfin and youtube plugins, and add ~/Videos as a local video source.";
        };

        inputstreamAdaptive = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install the inputstream-adaptive addon for Kodi (adaptive/DRM streaming, recommended for smooth Jellyfin and YouTube playback).";
          };
        };

        osmcSkin = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install the OSMC skin for Kodi (skin.osmc), selectable from Kodi's skin settings.";
          };
        };
      };
    };

    #################
    ## Downloaders ##
    #################
    downloaders = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Download tools: qbittorrent, jdownloader2, yt-dlp, varia, mullvad-vpn.";
      };

      qbittorrent = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable qBittorrent";
        };
      };

      jdownloader = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable jDownloader";
        };
      };
    };

    #############
    ## Privacy ##
    #############
    privacy = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Privacy/anonymity tools: tor, tor-browser, mullvad-vpn, apparmor, mat2.";
      };

      _1password = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable 1Password";
        };
      };

      enteauth = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Ente Auth";
        };
      };

      tor = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable TOR services";
        };
      };

      cryptocurrency = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Cryptocurrency";
        };
      };

      gpg = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable basic GnuPG";
        };

        kleopatra = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable KDE Kleopatra";
          };
        };
      };
    };

    ############
    ## Office ##
    ############
    office = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable general office setup (documents, PDFs, printing/scanning, communication apps). Sub-apps have their own enable flags.";
      };

      libre-office = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install LibreOffice.";
        };
      };

      marktext = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install and configure MarkText";
        };
      };

      typora = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install Typora";
        };
      };

      apostrophe = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install Gnomes Apostrophe";
        };
      };

      # well, more like handwritten notes, not artsy, mostly
      drawing = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable handwritten notes/drawing";
        };
      };
    };

    ############
    ## Notes ##
    ############
    notes = {
      obsidian = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Obsidian and other note tools";
        };
      };

      supernote = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install Tools for Supernote";
        };
      };
    };

    #########
    ## Uni ##
    #########
    uni = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable everything related to university (TU VPN, Anki, Typst, etc.).";
      };
    };

    ############
    ## Gaming ##
    ############
    gaming = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable general gaming setup (graphics, gamemode, ntsync kernel tweaks). Individual gaming apps have their own enable flags.";
      };

      steam = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install Steam";
        };
      };

      heroic = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install Heroic Games Launcher";
        };
      };
    };

    ###########
    ## Shell ##
    ###########
    shell = {
      zsh = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Home-manager zsh setup";
        };
      };
    };

    #############
    ## Browser ##
    #############
    browser = {
      firefox = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install and configure Firefox (home-manager programs.firefox, policies, profile, containers).";
        };
      };

      qutebrowser = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install and configure qutebrowser.";
        };
      };

      chromium = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install and configure Chromium (modules/chromium.nix).";
        };
      };

      # Per-webapp on/off switches. The actual name/url/icon catalog lives
      # in modules/webapps.nix, which feeds enabled entries into the
      # (internal, plural) cfg.browser.webapps list - hosts just flip these
      # instead of repeating the full webapp definition every time.
      webapp = {
        homeassistant = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable the Home Assistant webapp shortcut.";
          };
        };

        endel = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable the Endel webapp shortcut.";
          };
        };
      };
    };

    #############
    ## Desktop ##
    #############
    desktop = {
      gnome = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable GNOME desktop (GDM + gnome-shell). Conflicts with Hyprland - don't enable both.";
        };
      };

      hyprland = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Hyprland window manager + greetd, fuzzel, wofi, kdeconnect, noctalia, etc.";
        };
      };

      plasma = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable KDE Plasma 6 desktop (SDDM + plasma6). Independent of GNOME/Hyprland - don't enable more than one unless you mean to.";
        };
      };
    };

    ############
    ## Stylix ##
    ############
    # System-wide theming (modules/stylix). Always on - pick a curated theme
    # by name, not by color. See modules/stylix/themes for the available
    # themes and modules/stylix/default.nix for what gets themed.
    stylix = {
      theme = mkOption {
        type = types.enum [
          "catppuccin-mocha"
          "dracula"
          "gruvbox-dark"
          "nord"
          "booberry"
          "kanagawa"
        ];
        default = "catppuccin-mocha";
        description = "Curated system-wide theme name (modules/stylix/themes/<name>.nix). Applies everywhere Stylix theming reaches - GNOME, KDE Plasma, Hyprland, GTK/Qt, and theme-aware home-manager apps.";
      };

      fontsize = mkOption {
        type = types.ints.positive;
        default = 12;
        description = ''
          Base application font size in points (stylix.fonts.sizes.applications).
          Not every host has the same screen/DPI, so this is set per-host
          rather than hardcoded in modules/stylix.
        '';
      };
    };

    ############
    ## Server ##
    ############
    server = {
      forgejo = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Forgejo/Codeberg Actions runner. WIP, not fully working yet.";
        };
      };
    };

    ############
    ## Backup ##
    ############
    backup = {
      borgmatic = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Borgmatic backups to a remote Borg repository";
        };

        repositories = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                path = mkOption {
                  type = types.str;
                  description = "Borg repository URL or local path.";
                };

                passphraseKey = mkOption {
                  type = types.str;
                  default = "borg/encryption_keys/multi_hosts";
                  description = "Key inside encrypted/secrets.yaml holding the repository passphrase.";
                };

                sshKey = mkOption {
                  type = types.str;
                  default = "borg/multi_hosts";
                  description = "Key inside encrypted/ssh_keys.yaml holding the SSH key for this repository.";
                };
              };
            }
          );
          default = { };
          example = {
            borgbase.path = "ssh://gpfd4e0o@gpfd4e0o.repo.borgbase.com/./repo";
            nasimov = {
              path = "ssh://borg@nasimov/./rhodos";
              passphraseKey = "borg/encryption_keys/nasimov";
              sshKey = "borg/nasimov";
            };
          };
          description = "Repositories this host backs up to. Each one gets its own borgmatic configuration, credentials and retention run.";
        };

        directories = mkOption {
          type = types.listOf types.str;
          default = [ "/home/benjamin/Documents" ];
          example = [
            "/home/benjamin/Documents"
            "/home/benjamin/code"
          ];
          description = "Directories this host backs up.";
        };

        excludePatterns = mkOption {
          type = types.listOf types.str;
          default = [
            "*.pyc"
            "*/.cache"
            "*/node_modules"
            "*/result"
            "*/target"
          ];
          description = "Borg exclude patterns applied to every source directory.";
        };
      };
    };

    #############
    ## Socials and Communication ##
    #############
    socials = {
      irc = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "IRC Messaging";
        };
      };

      mastodon = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Mastodon Clients";
        };
      };
    };

    communication = {
      signal = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Signal Messenger";
        };
      };

      matrix = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Matrix Clients";
        };
      };

      mumble = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Mumble Voice Chats";
        };
      };

      meshtastic = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Meshtastic";
        };
      };

      mail = {
        thunderbird = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Thunderbird";
          };
        };

        tuta = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Tuta Mail and Calendar";
          };
        };
      };
    };

    ##########
    ## Apps ##
    ##########
    # Swappable application launch commands, so the actual app can be
    # changed in one place without touching keybindings (e.g. modules/hyprland/config/binds.lua).
    # NOTE: terminal/browser are intentionally *not* duplicated here - they
    # already live in cfg.env (see below) and binds.lua reuses those directly.
    apps = {
      emojiPicker = mkOption {
        type = types.str;
        default = "smile";
        description = "Command run to pick + copy an emoji (Hyprland SUPER + period bind).";
      };

      menu = mkOption {
        type = types.str;
        default = "wofi -d --hide-scroll --width=350 --location=center";
        description = "Fuzzy-menu/dmenu picker used by the unicode picker and clipboard-history binds.";
      };

      fileManager = mkOption {
        type = types.str;
        default = "nemo";
        description = "GUI file manager (Hyprland SUPER + E and the 'files' submap).";
      };

      codeEditor = mkOption {
        type = types.str;
        default = "zeditor";
        description = "GUI code editor (Hyprland SUPER + C and the 'code' submap).";
      };

      markdownEditor = mkOption {
        type = types.str;
        default = "marktext";
        description = "GUI text editor";
      };

      launcher = mkOption {
        type = types.str;
        default = "fuzzel";
        description = "Application launcher (Hyprland SUPER + SHIFT + D).";
      };

      screenshotTool = mkOption {
        type = types.str;
        default = "hyprshot";
        description = "Screenshot tool binary (Hyprland 'screen' submap and Print bind).";
      };
    };

    #########
    ## Env ##
    #########
    # General environment variables, exported wherever the shell (modules/shell/zsh.nix)
    # or other consumers pick them up.
    env = {
      editor = mkOption {
        type = types.str;
        default = "${pkgs.neovim}/bin/nvim";
        description = "Default $EDITOR / $VISUAL.";
      };

      terminal = mkOption {
        type = types.str;
        default = "${pkgs.kitty}/bin/kitty";
        description = "Default $TERMINAL.";
      };

      browser = mkOption {
        type = types.str;
        default = "firefox";
        description = "Default $BROWSER.";
      };

      pager = mkOption {
        type = types.str;
        default = "${pkgs.bat}/bin/bat";
        description = "Default $PAGER.";
      };
    };

    #####################################
    ## Modules (standalone / optional) ##
    #####################################
    modules = {
      latex = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install texliveMedium.";
        };
      };
    };
  };
}
