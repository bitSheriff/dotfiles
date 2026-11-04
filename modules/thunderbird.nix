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

  environment.systemPackages = with pkgs; [ ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin =
    lib.mkIf (lib.elem "benjamin" activeUsers && config.cfg.mail.thunderbird.enable)
      (
        { config, osConfig, ... }: {

          programs.thunderbird = {
          };
        }
      );
}
