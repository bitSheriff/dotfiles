# Android versions of the hledger/notes helpers.
#
# On the desktop these are zsh aliases (see ../../modules/hledger/default.nix).
# That does not work here: a home-screen shortcut or an `sh -c` invocation
# never loads an interactive shell, so everything the phone needs to launch
# from outside a shell has to be a real executable on PATH.
#
# All paths are baked in at build time but stay overridable from the
# environment, so ./home.nix and an interactive shell agree on the values.
{
  pkgs,
  paths,
}:

let
  hledgerScripts = import ../../modules/hledger/scripts.nix { inherit pkgs; };
  inherit (hledgerScripts) timedot-add timeclock-add;

  # Also exported by home.nix; repeated as defaults so the commands work even
  # when launched without a shell profile.
  defaults = ''
    NOTES_DIR="''${NOTES_DIR:-${paths.notesDir}}"
    FINANCE_PATH="''${FINANCE_PATH:-${paths.financePath}}"
    TIME_PATH="''${TIME_PATH:-${paths.timePath}}"
    export NOTES_DIR FINANCE_PATH TIME_PATH
  '';

  mkCmd =
    name: runtimeInputs: text:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = runtimeInputs ++ [ pkgs.coreutils ];
      text = defaults + "\n" + text;
    };

  # Prompt for a .timeclock file below $TIME_PATH and clock in or out of it.
  mkClk =
    name: action:
    mkCmd name
      [
        timeclock-add
        pkgs.fd
        pkgs.fzf
      ]
      ''
        REL_FILE=$(cd "$TIME_PATH" && fd --extension=timeclock --type f | fzf) || exit 0

        if [ -n "$REL_FILE" ]; then
            timeclock-add "$TIME_PATH/$REL_FILE" ${action}
        fi
      '';
in
{
  # The shared scripts, unchanged, so `timedot-add <file>` still works by hand.
  inherit (hledgerScripts) hl-accounts timedot-add timeclock-add;

  # Add a timedot entry to this year's file.
  tda = mkCmd "tda" [ timedot-add ] ''
    timedot-add "$TIME_PATH/private/$(date +%Y).timedot" "$@"
  '';

  # Add a timedot entry to the current semester's file.
  tdauni = mkCmd "tdauni" [ timedot-add ] ''
    timedot-add "$TIME_PATH/${paths.semesterTimedot}" "$@"
  '';

  # Add a timeclock entry to this year's work file.
  tdawork = mkCmd "tdawork" [ timeclock-add ] ''
    timeclock-add "$TIME_PATH/work/$(date +%Y).timeclock" "$@"
  '';

  clkin = mkClk "clkin" "i";
  clkout = mkClk "clkout" "o";

  # Commit the notes and push them if the Forgejo box answers.
  #
  # Two changes from the old shell function: `git -C` instead of plain `git`,
  # so the command is safe to launch from a shortcut in any directory, and a
  # TCP probe against the git port instead of ICMP, because unprivileged ping
  # is unreliable inside nix-on-droid's proot sandbox and port
  # ${toString paths.backupPort} is what the push actually needs.
  bknotes =
    mkCmd "bknotes"
      [
        pkgs.git
        pkgs.bashInteractive
      ]
      ''
        git -C "$NOTES_DIR" add -A
        git -C "$NOTES_DIR" commit -m "Backup from Pixel Phone" || true

        if timeout 2 bash -c "</dev/tcp/${paths.backupHost}/${toString paths.backupPort}" 2>/dev/null; then
            echo "✅ Server reachable"
            git -C "$NOTES_DIR" push
        else
            echo "❌ Server not reachable"
        fi
      '';

  # Re-attach the notes directory to the backup remote from scratch.
  # Destructive (it throws away the local history), so it asks first.
  bkinit =
    mkCmd "bkinit"
      [
        pkgs.git
        pkgs.gum
      ]
      ''
        gum confirm "Delete $NOTES_DIR/.git and pull the history again?" || exit 0

        rm -rf "''${NOTES_DIR:?}/.git"
        git -C "$NOTES_DIR" init
        git -C "$NOTES_DIR" remote add backup "${paths.backupRemote}"
        git -C "$NOTES_DIR" pull backup
      '';

  # Pull the dotfiles, then rebuild. The phone equivalent of `just switch`.
  dots-switch = mkCmd "dots-switch" [ pkgs.git ] ''
    DOTS="''${DOTFILES_PATH:-${paths.dotfilesDir}}"
    git -C "$DOTS" pull
    exec nix-on-droid switch --flake "$DOTS#${paths.configName}"
  '';
}
