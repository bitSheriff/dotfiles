{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.cfg.backup.borgmatic;
  hostName = config.networking.hostName;

  passphrasePath = config.sops.secrets.borg_passphrase.path;
  sshKeyPath = config.sops.secrets.borg_ssh_key.path;

  stateDir = "/var/lib/borgmatic";
  knownHosts = "${stateDir}/known_hosts";

  # borgmatic runs as root, so the key and the known_hosts file live outside
  # any home directory. accept-new pins the host key on first contact instead
  # of trusting it again on every run.
  sshCommand = lib.concatStringsSep " " [
    "${pkgs.openssh}/bin/ssh"
    "-i ${sshKeyPath}"
    "-o BatchMode=yes"
    "-o StrictHostKeyChecking=accept-new"
    "-o UserKnownHostsFile=${knownHosts}"
  ];

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

      repo="${cfg.repository}"
      BORG_PASSPHRASE="$(cat ${passphrasePath})"
      BORG_RSH="${sshCommand}"
      export BORG_PASSPHRASE BORG_RSH

      # borg reports every SSH problem as "Is borg working on the server?",
      # which sends you hunting on the wrong side of the connection.
      host="''${repo#ssh://}"
      host="''${host%%/*}"
      if ! ssh_err=$(${sshCommand} -o ConnectTimeout=15 "$host" true 2>&1); then
        case "$ssh_err" in
          *"Permission denied"*)
            echo "SSH rejected the backup key. Register this public key on the repository:" >&2
            ssh-keygen -y -f ${sshKeyPath} >&2
            ssh-keygen -lf ${sshKeyPath} >&2
            exit 1
            ;;
        esac
      fi

      if borg info "$repo" >/dev/null 2>&1; then
        echo "repository already initialized: $repo"
        exit 0
      fi

      borg init --encryption repokey-blake2 "$repo"
      echo "initialized $repo"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {

    environment.systemPackages = [
      borg-init
      pkgs.borgbackup
    ];

    sops.secrets = {
      borg_passphrase = {
        sopsFile = ../encrypted/secrets.yaml;
        key = "borg/encryption_keys/multi_hosts";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      borg_ssh_key = {
        sopsFile = ../encrypted/ssh_keys.yaml;
        key = "borg/multi_hosts";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    services.borgmatic = {
      enable = true;

      configurations.${hostName} = {
        source_directories = cfg.directories;

        repositories = [
          {
            path = cfg.repository;
            label = "borgbase";
          }
        ];

        exclude_patterns = cfg.excludePatterns;
        exclude_caches = true;
        exclude_if_present = [ ".nobackup" ];
        one_file_system = true;

        encryption_passcommand = "${pkgs.coreutils}/bin/cat ${passphrasePath}";
        ssh_command = sshCommand;

        archive_name_format = "${hostName}-{now:%Y-%m-%dT%H:%M:%S}";

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

        retries = 2;
        retry_wait = 60;
      };
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
