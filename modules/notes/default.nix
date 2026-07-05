{ config, pkgs, ... }:

let
  notes = pkgs.writeShellApplication {
    name = "notes";
    runtimeInputs = [
      pkgs.fd
      pkgs.fzf
      pkgs.gnused
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      # Ensure NOTES_DIR is set
      if [[ -z "''${NOTES_DIR:-}" ]]; then
          echo "Error: NOTES_DIR is not set. Please set it to the directory where your notes are stored."
          exit 1
      fi

      editor="''${1:-nvim}" # Use the first argument if provided, otherwise default to nvim

      (
          cd "$NOTES_DIR" || exit 1 # Exit if NOTES_DIR cannot be changed to
          file="$(fd --extension md | fzf || true)"             # Capture the output of tv files
          # Trim and sanitize the file name
          if [[ -n "$file" ]]; then
              sanitized_file=$(echo "$file" | sed 's/[{}]//g' | xargs)
              if [[ -f "$sanitized_file" ]]; then
                  # Use the editor to open the selected file
                  "$editor" "$sanitized_file"
              else
                  echo "Error: No valid file selected or file does not exist."
              fi
          fi
      )
    '';
  };

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

  environment.systemPackages = with pkgs; [
    obsidian # the best note system
    gum # for cli inputs
    fd # find files
    fzf # to select files

    notes
  ];

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
