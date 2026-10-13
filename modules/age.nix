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
    age
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin =
    lib.mkIf (lib.elem "benjamin" activeUsers && config.cfg.socials.irc.enable)
      (
        { config, osConfig, ... }: {

          home.sessionVariables = {
            # path where different age keys are stored
            AGE_KEY_DIR = "$HOME/.age";
          };

          sops.secrets = {
            age_key_llk = {
              sopsFile = ../encrypted/age_keys.yaml;
              key = "llk";
              path = "${config.home.homeDirectory}/.age/llk.key";
            };
          };

        }
      );
}
