{
  config,
  inputs,
  pkgs,
  ...
}:

{

  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.packages = [ pkgs.sops ];
  # Tell agenix where to find the decryption key on the server
  age.identityPaths = [ "~/.age" ];

  sops = {
    # Default secret file location
    defaultSopsFile = ../encrypted/secrets.yaml;
    # Path to your decryption key (Home Manager path)
    age.keyFile = "${config.home.homeDirectory}/.age/dotfiles.key";

    secrets = {
      "openai_api_key" = {
        key = "api_keys/openai";
      };
      "github_access_token" = {
        key = "access_token/github";
      };

      "uni_email" = {
        key = "uni/email";
      };
      "uni_password" = {
        key = "uni/password";
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

  # load the data from the files into environment variables
  programs.zsh.initContent = ''
    export GITHUB_TOKEN="$(cat ${config.sops.secrets.github_access_token.path})"
  '';

}
