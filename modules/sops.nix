{
  config,
  pkgs,
  ...
}:

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
      "github_access_token" = {
        key = "access_token/github";
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
