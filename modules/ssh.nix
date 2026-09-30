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

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    # link the ssh config
    home.file.".ssh/config".text = ''
      Include ~/.ssh/hosts
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
        ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

}
