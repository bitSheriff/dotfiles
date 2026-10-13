{
  config, # Top-level NixOS config
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
{
  imports = [ ];

  environment.systemPackages = with pkgs; [
    gnupg
    kdePackages.kleopatra # GUI
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin =
    lib.mkIf (lib.elem "benjamin" activeUsers && config.cfg.socials.irc.enable)
      (
        { config, osConfig, ... }: {
          programs.gpg = {
            enable = true;

          };
        }
      );
}
