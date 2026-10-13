# SSH keys and the shared host list from sops: the phone's edition of the
# home-manager half of ../../modules/ssh.nix.
#
# sops-nix is deliberately not used here. Its home-manager module installs
# secrets only through a systemd user service; the activation hook does no
# more than `systemctl restart --user sops-nix`, and skips even that when no
# user systemd is running, which is always the case under nix-on-droid. On
# top of that, its sops-install-secrets helper is a Go binary that no binary
# cache carries for aarch64-linux, so it would have to be compiled on the
# phone under proot. Plain `sops -d` from nixpkgs is cached and does the one
# thing needed, so the decryption is a short activation step instead.
#
# The result is the same ~/.ssh layout as on the desktop (~/.ssh/private,
# ~/.ssh/uni, ~/.ssh/work plus their .pub halves and ~/.ssh/hosts), so the
# shared hosts file, which names those IdentityFile paths, works unchanged.
# There is no ssh-agent on the phone; ssh reads the key files directly.
#
# The phone gets its own age key, like every other host in ../../.sops.yaml.
# One-time setup, on the phone:
#
#   mkdir -p ~/.age && age-keygen -pq -o ~/.age/dotfiles.key
#
# then add the printed public key to .sops.yaml as `&android` and to the
# creation_rules recipients, run `nix run .#update-keys` on a machine that
# already holds a key, commit, push, and `dots-switch` here. Until the key
# exists the step below only prints a reminder, so a fresh bootstrap is not
# blocked by it.
{ pkgs, ... }:

let
  paths = import ./paths.nix;

  ageKeyFile = "${paths.homeDir}/.age/dotfiles.key";
  sshDir = "${paths.homeDir}/.ssh";

  # Same three keys as ../../modules/ssh.nix. Only the private half is stored
  # in sops; the public half is derived from it after decryption.
  keys = [
    "private"
    "uni"
    "work"
  ];

  # The encrypted files go into the store as-is; that is fine, they are
  # ciphertext. sops picks the format from the extension, which the store path
  # keeps: .yaml for the keys, .txt (= binary) for the hosts file.
  sshKeysFile = ../../encrypted/ssh_keys.yaml;
  sshHostsFile = ../../encrypted/ssh_hosts.txt;

  sopsBin = "${pkgs.sops}/bin/sops";
  sshKeygenBin = "${pkgs.openssh}/bin/ssh-keygen";
in
{
  environment.packages = with pkgs; [
    sops
    age # age-keygen for the one-time key setup, and for `pass`-style ad-hoc use
  ];

  # So `sops edit encrypted/...` works from the dotfiles clone on the phone
  # too, without spelling the key path out every time.
  environment.sessionVariables.SOPS_AGE_KEY_FILE = ageKeyFile;

  build.activationAfter.sshKeys = ''
    if [[ -v DRY_RUN ]]; then
      echo "Would decrypt the SSH keys (${toString keys}) and ~/.ssh/hosts into ${sshDir}"
    elif [ ! -r "${ageKeyFile}" ]; then
      echo "No age key at ${ageKeyFile}, the SSH keys from sops stay uninstalled."
      echo "Create one with:  mkdir -p ~/.age && age-keygen -pq -o ${ageKeyFile}"
      echo "then add its public key to .sops.yaml and re-encrypt, see hosts/android/ssh.nix."
    else
      export SOPS_AGE_KEY_FILE="${ageKeyFile}"
      mkdir -p "${sshDir}"
      chmod 700 "${sshDir}"

      # Decrypt next to the target and rename, so a failed decryption can
      # never leave a truncated key behind. umask keeps the temp file private
      # from the first byte.
      umask 077

      for k in ${toString keys}; do
        priv="${sshDir}/$k"
        tmp="$priv.tmp"
        if ${sopsBin} --decrypt --extract "[\"$k\"][\"priv\"]" ${sshKeysFile} > "$tmp"; then
          chmod 600 "$tmp"
          mv -f "$tmp" "$priv"
          ${sshKeygenBin} -y -f "$priv" > "$priv.pub.tmp"
          chmod 644 "$priv.pub.tmp"
          mv -f "$priv.pub.tmp" "$priv.pub"
        else
          rm -f "$tmp"
          errorEcho "Could not decrypt the SSH key '$k'. Is this phone's age key a recipient in .sops.yaml?"
        fi
      done

      if ${sopsBin} --decrypt ${sshHostsFile} > "${sshDir}/hosts.tmp"; then
        chmod 600 "${sshDir}/hosts.tmp"
        mv -f "${sshDir}/hosts.tmp" "${sshDir}/hosts"
      else
        rm -f "${sshDir}/hosts.tmp"
        errorEcho "Could not decrypt ~/.ssh/hosts."
      fi
    fi
  '';
}
