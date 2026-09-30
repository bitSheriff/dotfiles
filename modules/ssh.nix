{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    xauth # needed to forward X11 Sessions
    xhost
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # Disable password login (only SSH keys are allowed)
      PermitRootLogin = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  users.users.benjamin = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaKM4Dwfago4s/0Ap9hFHZMmqoly90mS/3rEl+7prJx"
    ];
  };

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) (
    { config, ... }:
    let
      # Private keys decrypted by sops-nix (see users/benjamin.nix, ssh_key_*
      # secrets) that should be loaded into the agent. Only the private half
      # is stored in sops - the public half is derived on activation below,
      # since it's trivially reproducible from the private key and isn't
      # secret. Add new key basenames here as more sops ssh_key_* secrets
      # are added.
      keys = [
        "private"
        "uni"
        "work"
      ];
      keysList = lib.concatStringsSep " " keys;
    in
    {
      # link the ssh config
      home.file.".ssh/config".text = ''
        Host *
          IdentityAgent SSH_AUTH_SOCK

        Include ~/.ssh/hosts
      '';

      # Derive each key's public half from its sops-decrypted private half,
      # instead of storing a redundant *_pub secret in sops. Runs after the
      # sops secrets are written so the private keys already exist.
      home.activation.deriveSshPubkeys = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        for k in ${keysList}; do
          priv="$HOME/.ssh/$k"
          pub="$HOME/.ssh/$k.pub"
          if [ -e "$priv" ]; then
            $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -y -f "$priv" > "$pub.tmp"
            $DRY_RUN_CMD chmod 644 "$pub.tmp"
            $DRY_RUN_CMD mv -f "$pub.tmp" "$pub"
          fi
        done
      '';

      # Native ssh-agent (replaces the 1Password SSH agent). Keys live in
      # ~/.ssh, decrypted by sops-nix. git commit signing (ssh-keygen -Y sign)
      # requires the private key to be loaded into a running agent, so we
      # auto-load it once the agent and the sops secret are both available.
      services.ssh-agent.enable = true;

      systemd.user.services.ssh-add-keys = {
        Unit = {
          Description = "Load SSH keys into ssh-agent";
          After = [
            "ssh-agent.service"
            "sops-nix.service"
          ];
          Requires = [ "ssh-agent.service" ];
          PartOf = [ "ssh-agent.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
          ExecStart = "${pkgs.openssh}/bin/ssh-add ${lib.concatMapStringsSep " " (k: "%h/.ssh/${k}") keys}";
        };
        Install.WantedBy = [ "default.target" ];
      };
    }
  );

}
