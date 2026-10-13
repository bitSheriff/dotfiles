# GPG: public half declared via programs.gpg, secret half from sops.
#
# programs.gpg can only manage public keys and trust; its key files land in
# the world-readable Nix store, so the secret key cannot go through it. That
# one is a sops secret, imported into the keyring on activation, the same way
# ./ssh.nix installs the SSH keys. Import is idempotent.
#
# mutableKeys stays at its default (true) on purpose: false rebuilds the
# keyring from publicKeys on every activation and would throw the imported
# secret key out again each time.
{
  pkgs,
  lib,
  activeUsers,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    kdePackages.kleopatra # GUI
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) (
    { config, ... }:
    let
      # One entry per key. Each needs a `<name>/priv` entry in
      # ../../encrypted/gpg_keys.yaml and a `<name>.pub.asc` file next to this
      # module (`gpg --export --armor <name>`).
      keys = [
        "bitSheriff"
      ];

      secretName = k: "gpg_key_${lib.toLower k}";
      secretPaths = map (k: config.sops.secrets.${secretName k}.path) keys;
      gpg = "${config.programs.gpg.package}/bin/gpg";
    in
    {
      programs.gpg = {
        enable = true;

        # Public by nature, fine in git. All of them are our own keys, hence
        # ultimate trust across the board.
        publicKeys = map (k: {
          source = ./${k}.pub.asc;
          trust = "ultimate";
        }) keys;
        # The trust database is generated from the list above.
        mutableTrust = false;
      };

      # SSH support stays off: ./ssh.nix runs home-manager's ssh-agent for the
      # sops-managed SSH keys, and a second agent would compete for
      # SSH_AUTH_SOCK.
      services.gpg-agent = {
        enable = true;
        enableSshSupport = false;
        pinentry.package = pkgs.pinentry-qt; # Qt, matching Kleopatra
      };

      # Only the private halves, armored (`gpg --export-secret-keys --armor`).
      sops.secrets = lib.listToAttrs (
        map (
          k:
          lib.nameValuePair (secretName k) {
            sopsFile = ../../encrypted/gpg_keys.yaml;
            key = "${k}/priv";
          }
        ) keys
      );

      # Not a home.activation step: during activation sops-nix only restarts
      # its user service, and from inside home-manager-benjamin.service that
      # happens after all activation steps, so on the switch that first adds
      # the secret the file is not there yet. A user service ordered after
      # sops-nix.service runs exactly when the secret exists, on every switch
      # and at login. Same pattern as ssh-add-keys in ../ssh.nix.
      systemd.user.services.import-gpg-key = {
        Unit = {
          Description = "Import the sops-managed GPG secret key into the keyring";
          After = [ "sops-nix.service" ];
          Requires = [ "sops-nix.service" ];
          PartOf = [ "sops-nix.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${gpg} --batch --quiet --import ${lib.concatStringsSep " " secretPaths}";
        };
        Install.WantedBy = [ "default.target" ];
      };
    }
  );
}
