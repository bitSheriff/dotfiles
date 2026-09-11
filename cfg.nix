{ lib, pkgs, ... }:

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

      ebooks = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable ebook reading";
        };
      };

      comics = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable comic books reading";
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
        default = "BEMOJI_PICKER_CMD='wofi -d --hide-scroll --width=350 --location=center' bemoji -n -e | wl-copy";
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
        # Bare name on purpose: PATH resolves to the home-manager-wrapped firefox,
        # which carries the generated policies.json (and therefore the extensions).
        # A "${pkgs.firefox}/bin/firefox" store path is the unwrapped build with
        # {"policies":{}} — it installs none of the extensions defined below.
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
    # Most modules/* are always-on building blocks pulled in by a
    # collection or by modules/common.nix & friends. These few are
    # standalone / not part of any collection, so they get their own
    # opt-in flag (default off).
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
