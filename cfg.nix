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

{
  options.cfg = {
    notes = {
      obsidian = mkOption {
        type = types.bool;
        default = false;
        description = "Install and configure Obsidian, the note-taking app.";
      };
    };

    ############
    ## Office ##
    ############
    office = {
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
  };
}
