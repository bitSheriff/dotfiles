{ lib, ... }:

# Central place to declare toggleable "features" for this flake.
#
# Instead of enabling a module/collection simply by importing its file,
# modules can now check `config.cfg.<...>` and stay imported everywhere,
# but only actually install/configure themselves when a host opts in.
#
# Usage inside a module:
#   { config, lib, pkgs, ... }:
#   {
#     config = lib.mkIf config.cfg.notes.obsidian {
#       environment.systemPackages = [ pkgs.obsidian ];
#     };
#   }
#
# Usage inside flake.nix, per host:
#   {
#     cfg.notes.obsidian = true;
#     cfg.office.libre-office.enable = true;
#   }

with lib;

let
  # Auto-import every top-level entry in ./collections and ./modules so
  # hosts never need to hand-list them in flake.nix. A "top-level entry"
  # is either a *.nix file, or a directory that has its own default.nix
  # (so nested implementation-detail files, like modules/hyprland's
  # hyprlock.nix, aren't imported standalone - only their parent dir is).
  #
  # Most modules are already unconditionally active once imported (they
  # were designed that way, e.g. modules/common.nix, modules/zathura.nix).
  # Collections and a handful of standalone/optional modules gate their
  # own config behind `cfg.<name>.enable` below, so importing everything
  # unconditionally here is safe - a host simply flips the flags it wants.
  scanDir =
    dir:
    map (name: dir + "/${name}") (
      attrNames (
        filterAttrs (
          name: type:
          (type == "regular" && hasSuffix ".nix" name)
          || (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
        ) (builtins.readDir dir)
      )
    );
in
{
  imports = scanDir ./collections ++ scanDir ./modules;

  options.cfg = {
    notes = {
      obsidian = mkOption {
        type = types.bool;
        default = false;
        description = "Install and configure Obsidian, the note-taking app.";
      };
    };

    #################
    ## Development ##
    #################
    development = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Development tooling: editors, terminals, languages, vscode, direnv, git, etc.";
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
