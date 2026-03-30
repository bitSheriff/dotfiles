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

      "qutebrowser_urls" = {
        sopsFile = ../encrypted/qutebrowser_urls.txt;
        format = "binary";
        path = "${config.home.homeDirectory}/.config/qutebrowser/bookmarks/urls";
      };

      "ssh_hosts" = {
        sopsFile = ../encrypted/ssh_hosts.txt;
        format = "binary";
        path = "${config.home.homeDirectory}/.ssh/hosts";
      };
    };
  };

  # To use an "API" secret in your shell or apps:
  home.sessionVariables = {
    # This points to the decrypted file containing the key
    OPENAI_API_KEY_PATH = config.sops.secrets.openai_api_key.path;
  };
}
