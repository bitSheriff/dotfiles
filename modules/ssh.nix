{
  config,
  pkgs,
  username,
  ...
}:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # Disable password login (only SSH keys are allowed)
      PermitRootLogin = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaKM4Dwfago4s/0Ap9hFHZMmqoly90mS/3rEl+7prJx"
    ];
  };

  home-manager.users.${username} =
    { config, ... }:
    {
      home.file.".config/1Password/ssh/agent.toml".text = ''
        [[ssh-keys]]
        vault = "bitSheriff"
      '';

      # link the ssh config
      home.file.".ssh/config".text = ''
        Include ~/.ssh/hosts

        Host *
          IdentityAgent ~/.1password/agent.sock
      '';

    };
}
