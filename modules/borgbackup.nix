{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.cfg.backup.borgmatic;
  hostName = config.networking.hostName;
  repos = cfg.repositories;

  stateDir = "/var/lib/borgmatic";
  knownHosts = "${stateDir}/known_hosts";

  passSecret = name: "borg_${name}_passphrase";
  sshSecret = name: "borg_${name}_ssh_key";
  passPath = name: config.sops.secrets.${passSecret name}.path;
  sshPath = name: config.sops.secrets.${sshSecret name}.path;

  # borgmatic runs as root, so keys and known_hosts live outside any home
  # directory. accept-new pins the host key on first contact instead of
  # trusting it anew on every run.
  sshCommand =
    name:
    lib.concatStringsSep " " [
      "${pkgs.openssh}/bin/ssh"
      "-i ${sshPath name}"
      "-o BatchMode=yes"
      "-o StrictHostKeyChecking=accept-new"
      "-o UserKnownHostsFile=${knownHosts}"
    ];

  initRepo = name: repo: ''
    if [ "$want" = "all" ] || [ "$want" = "${name}" ]; then
      matched=1
      echo "== ${name}: ${repo.path}"

      BORG_PASSPHRASE="$(cat ${passPath name})"
      BORG_RSH="${sshCommand name}"
      export BORG_PASSPHRASE BORG_RSH

      if out=$(borg info "${repo.path}" 2>&1); then
        echo "   already initialized"
      else
        case "$out" in
          # borg reports every SSH problem as "Is borg working on the server?",
          # which sends you hunting on the wrong side of the connection.
          *"Permission denied"*)
            echo "   SSH rejected the key, register this public key on the repository:" >&2
            ssh-keygen -y -f ${sshPath name} >&2
            ssh-keygen -lf ${sshPath name} >&2
            rc=1
            ;;
          *"does not exist"*)
            borg init --encryption repokey-blake2 "${repo.path}"
            echo "   initialized"
            ;;
          *)
            echo "$out" >&2
            rc=1
            ;;
        esac
      fi
    fi
  '';

  borg-init = pkgs.writeShellApplication {
    name = "borg-init";
    runtimeInputs = with pkgs; [
      borgbackup
      coreutils
      openssh
    ];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        echo "borg-init must run as root, the secrets are root-only" >&2
        exit 1
      fi

      install -d -m 0700 ${stateDir}

      want="''${1:-all}"
      matched=0
      rc=0

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList initRepo repos)}

      if [ "$matched" -eq 0 ]; then
        echo "unknown repository: $want" >&2
        echo "known: ${lib.concatStringsSep " " (lib.attrNames repos)}" >&2
        exit 1
      fi

      exit "$rc"
    '';
  };

  borgmaticConfig = name: repo: {
    source_directories = cfg.directories;

    repositories = [
      {
        path = repo.path;
        label = name;
      }
    ];

    exclude_patterns = cfg.excludePatterns;
    exclude_caches = true;
    exclude_if_present = [ ".nobackup" ];
    one_file_system = true;

    encryption_passcommand = "${pkgs.coreutils}/bin/cat ${passPath name}";
    ssh_command = sshCommand name;

    compression = "zstd,3";

    archive_name_format = "${hostName}-{now:%Y-%m-%dT%H:%M:%S}";
    # match_archives = "sh:${hostName}-*"; # only show selected archives

    keep_daily = 7;
    keep_weekly = 4;
    keep_monthly = 6;

    checks = [
      {
        name = "repository";
        frequency = "2 weeks";
      }
      {
        name = "archives";
        frequency = "1 month";
      }
    ];

    lock_wait = 300;
    retries = 2;
    retry_wait = 60;
  };
in
{
  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = repos != { };
        message = "cfg.backup.borgmatic is enabled but no repositories are defined.";
      }
    ];

    environment.systemPackages = [
      borg-init
      pkgs.borgbackup
    ];

    sops.secrets = lib.listToAttrs (
      lib.concatLists (
        lib.mapAttrsToList (name: repo: [
          (lib.nameValuePair (passSecret name) {
            sopsFile = ../encrypted/secrets.yaml;
            key = repo.passphraseKey;
            owner = "root";
            group = "root";
            mode = "0400";
          })
          (lib.nameValuePair (sshSecret name) {
            sopsFile = ../encrypted/ssh_keys.yaml;
            key = repo.sshKey;
            owner = "root";
            group = "root";
            mode = "0400";
          })
        ]) repos
      )
    );

    services.borgmatic = {
      enable = true;

      # One configuration per repository: own credentials, own lock, and a
      # failing target does not take the others down with it.
      configurations = lib.mapAttrs' (
        name: repo: lib.nameValuePair "${hostName}-${name}" (borgmaticConfig name repo)
      ) repos;
    };

    # Drop-ins on top of the units shipped by the borgmatic package.
    systemd.services.borgmatic = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        StateDirectory = "borgmatic";
        StateDirectoryMode = "0700";
        Nice = 19;
        IOSchedulingClass = "idle";
        CPUSchedulingPolicy = "batch";
      };
    };

    systemd.timers.borgmatic.timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "3h";
      Persistent = true;
    };
  };
}
