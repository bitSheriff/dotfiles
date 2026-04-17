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
  age.identityPaths = [ "~/.age" ];

  sops = {
    defaultSopsFile = ../encrypted/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.age/dotfiles.key";

    secrets = {
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

      # API Keys and Access Tokens

      "api/openai" = {
        key = "api_keys/openai";
      };

      "access/github" = {
        key = "access_token/github";
      };

    };
  };

  # load the data from the files into environment variables
  programs.zsh.initContent = ''
    export GITHUB_TOKEN="$(cat ${config.sops.secrets."access/github".path})"
  '';

}
