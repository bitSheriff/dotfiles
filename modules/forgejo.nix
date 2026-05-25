{ pkgs, config, ... }:
{
  # !!WIP!! does not work yet
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "${config.networking.hostName}";
      url = "https://codeberg.org";
      # Obtaining the path to the runner token file may differ
      # tokenFile should be in format TOKEN=<secret>, since it's EnvironmentFile for systemd
      tokenFile = config.sops.secrets.codeberg_runner_token.path;
      labels = [
        "ubuntu-latest:docker://node:16-bullseye"
        ## optionally provide native execution on the host:
        "native:host"
        "nixos:host"
      ];
      hostPackages = with pkgs; [
        nix
        git
        bash
        coreutils
      ];
    };
  };
}
