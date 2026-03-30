{ config, pkgs, ... }:

{
  home.packages = [ pkgs.sops ];

  sops = {
    # Default secret file location
    defaultSopsFile = ../encrypted/secrets.yaml;
    # Path to your decryption key (Home Manager path)
    age.keyFile = "${config.home.homeDirectory}/.age/dotfiles.key";

    secrets = {
      "openai_api_key" = {
        key = "api_keys/openai";
      };

  #     "my_secret_config" = {
  #       sopsFile = ../encrypted/secretConf.txt;
  #       format = "binary";
  #       path = "${config.home.homeDirectory}/.config/secretConf";
  #     };
    };
  };

  # # To use an "API" secret in your shell or apps:
    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.age/dotfiles.key";
      OPENAI_API_KEY_PATH = config.sops.secrets.openai_api_key.path;
    };
}
