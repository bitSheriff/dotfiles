{ lib, ... }:

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
          description = "Home-manager zsh setup (programs.zsh, aliases, history, atuin/direnv/starship/fzf/ripgrep integrations) plus the bundled home-made shell scripts (modules/shell/scripts.nix).";
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
