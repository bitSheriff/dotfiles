{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  dotfiles_path,
  ...
}:
let
  # The script itself lives in ./scripts/pass.nix, mirroring the
  # ../git/scripts.nix and ../hledger/scripts.nix pattern.
  pass = import ./scripts/pass.nix { inherit pkgs; };
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  environment.systemPackages = [
    pass
  ];

  # System Wide Secrets
  sops = {
    defaultSopsFile = ../../encrypted/secrets.yaml;
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
        sopsFile = ../../encrypted/ssh_keys.yaml;
        key = "root/priv";
        path = "/root/.ssh/id_ed25519";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };
}
