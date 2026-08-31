{
  config,
  lib,
  pkgs,
  ...
}:

let
  notes_script = import ./notes.nix { inherit pkgs; };

in
{
  imports = [
    ./jour.nix # for handling journal entries
    ./todo.nix # for handling todo and inbox items
    ./memo.nix # for handling memos
    ./obsidian.nix # obsidian stuff
  ];

  environment.sessionVariables = {
    NOTES_DIR = "$HOME/notes";
    INBOX = "$HOME/notes/Inbox/Inbox.md";
    INBOX_DIR = "$HOME/notes/Inbox";
    JOURNAL_DAILY_PATH = "$HOME/notes/Journal/Daily";
    JOURNAL_WEEKLY_PATH = "$HOME/notes/Journal/Weekly";
  };

  environment.systemPackages =
    with pkgs;
    [
      gum # for cli inputs
      fd # find files
      fzf # to select files

      notes_script
    ]
    ++ lib.optionals config.cfg.notes.obsidian [ obsidian ]; # the best note system

  programs.zsh.shellAliases = {
    daily = "jour";
    weekly = "jour --weekly";
  };

  systemd.user.services.note-backup = {
    description = "Backup notes daily with git";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "note-backup" ''
        # Ensure NOTES_DIR is set, fallback to ~/notes
        NOTES_DIR="''${NOTES_DIR:-$HOME/notes}"
        if [ ! -d "$NOTES_DIR" ]; then
          echo "Notes directory $NOTES_DIR does not exist."
          exit 0
        fi

        cd "$NOTES_DIR"

        if [ ! -d .git ]; then
          echo "Initializing git repository in $NOTES_DIR"
          ${pkgs.git}/bin/git init
        fi

        # Ensure git config has user and email (local settings to avoid failure)
        if ! ${pkgs.git}/bin/git config user.name >/dev/null 2>&1; then
          ${pkgs.git}/bin/git config --local user.name "Note Backup Service"
        fi
        if ! ${pkgs.git}/bin/git config user.email >/dev/null 2>&1; then
          ${pkgs.git}/bin/git config --local user.email "note-backup@localhost"
        fi

        ${pkgs.git}/bin/git add -A

        # Check if there are changes to commit, otherwise do nothing
        if ! ${pkgs.git}/bin/git diff --cached --quiet; then
          ${pkgs.git}/bin/git commit --no-gpg-sign -m "$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M')"
        fi

        # add NAS server as backup
        ${pkgs.git}/bin/git remote add backup ssh://git@10.0.0.151:2222/bitSheriff/notes.git || true

        # create a unique branch
        ${pkgs.git}/bin/git checkout -B $(hostname)
        ${pkgs.git}/bin/git push origin
      ''}";
    };
  };

  systemd.user.timers.note-backup = {
    description = "Timer for daily note backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
