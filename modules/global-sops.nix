{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:

{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  # System Wide Secrets
  sops = {
    defaultSopsFile = ../encrypted/secrets.yaml;
    secrets = {
      # User passwords
      user-benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
        key = "hosts/${config.networking.hostName}/benjamin";
        neededForUsers = true;
      };

      "nix_cache_priv" = {
        key = "nix/cache/rhodos/priv";
      };

      codeberg_runner_token = {
        key = "access_token/forgejo_runner/codeberg/token";
      };

      # root needs this ssh key to update the nix store from known devices (like a private nix cache)
      root_ssh_key = {
        key = "ssh/root/priv";
        path = "/root/.ssh/id_ed25519";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

  };
}
