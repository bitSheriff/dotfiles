{
  config, # Top-level NixOS config
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
    age
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) (
    { config, osConfig, ... }: {

      home.sessionVariables = {
        # path where different age keys are stored
        AGE_KEY_DIR = "$HOME/.age";
      };

      # Private Keys
      sops.secrets = {
        age_key_llk = {
          sopsFile = ../../encrypted/age_keys.yaml;
          key = "llk";
          path = "${config.home.homeDirectory}/.age/llk.key";
        };

        age_key_backup_nasimov = {
          sopsFile = ../../encrypted/age_keys.yaml;
          key = "backup_nasimov";
          path = "${config.home.homeDirectory}/.age/backup_nasimov.key";
        };
      };

      # Public Keys / Recipients
      home.file.".age/recipients/llk.pub".source = ./llk.pub;
      home.file.".age/recipients/hosts/rhodos.pub".source = ./rhodos.pub;
      home.file.".age/recipients/hosts/delos.pub".source = ./delos.pub;
      home.file.".age/recipients/hosts/android.pub".source = ./android.pub;

    }
  );
}
