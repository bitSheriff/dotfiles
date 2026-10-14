# GPG: every key comes from sops, our own secret keys as well as the public
# keys of the people we write to. programs.gpg.publicKeys is deliberately not
# used: it copies the key files into the world-readable Nix store, and a list
# of correspondents is nothing to publish either.
#
# Everything listed in `keys` is imported into the keyring by a user service
# ordered after sops-nix, the same way ./ssh.nix installs the SSH keys. Import
# is idempotent. Keys whose secret half is in the keyring, i.e. our own, get
# ultimate ownertrust; contacts are certified once by hand in Kleopatra
# (Certify), which the import does not undo because the keyring stays mutable.
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
      # sops paths inside ../../encrypted/gpg_keys.yaml, one per armored key
      # block. Own keys as `gpg --export-secret-keys --armor` (that export
      # carries the public half too), contacts as `gpg --export --armor`.
      keys = [
        # Private Keys
        "bitSheriff"

        # Public Keys / Contacts
      ];

      secretName = k: "gpg_key_" + lib.toLower (lib.replaceStrings [ "/" ] [ "_" ] k);
      secretPaths = map (k: config.sops.secrets.${secretName k}.path) keys;
      gpg = "${config.programs.gpg.package}/bin/gpg";

      importKeys = pkgs.writeShellScript "import-gpg-keys" ''
        set -euo pipefail
        ${gpg} --batch --quiet --import ${lib.escapeShellArgs secretPaths}

        # Ultimate trust for every key we hold the secret half of. In the
        # colon output the primary key's fingerprint is the fpr line directly
        # after its sec line; subkeys have their own fpr lines, skipped here.
        ${gpg} --batch --with-colons --list-secret-keys \
          | ${pkgs.gawk}/bin/awk -F: '
              $1 == "sec" { want = 1; next }
              want && $1 == "fpr" { print $10 ":6:"; want = 0 }' \
          | ${gpg} --batch --quiet --import-ownertrust
      '';
    in
    {
      programs.gpg.enable = true;

      # SSH support stays off: ./ssh.nix runs home-manager's ssh-agent for the
      # sops-managed SSH keys, and a second agent would compete for
      # SSH_AUTH_SOCK.
      services.gpg-agent = {
        enable = true;
        enableSshSupport = false;
        pinentry.package = pkgs.pinentry-qt; # Qt, matching Kleopatra
      };

      sops.secrets = lib.listToAttrs (
        map (
          k:
          lib.nameValuePair (secretName k) {
            sopsFile = ../../encrypted/gpg_keys.yaml;
            key = k;
          }
        ) keys
      );

      # Not a home.activation step: during activation sops-nix only restarts
      # its user service, and from inside home-manager-benjamin.service that
      # happens after all activation steps, so on the switch that first adds
      # a secret the file is not there yet. A user service ordered after
      # sops-nix.service runs exactly when the secrets exist, on every switch
      # and at login. Same pattern as ssh-add-keys in ../ssh.nix.
      systemd.user.services.import-gpg-keys = {
        Unit = {
          Description = "Import the sops-managed GPG keys into the keyring";
          After = [ "sops-nix.service" ];
          Requires = [ "sops-nix.service" ];
          PartOf = [ "sops-nix.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = importKeys;
        };
        Install.WantedBy = [ "default.target" ];
      };
    }
  );
}
