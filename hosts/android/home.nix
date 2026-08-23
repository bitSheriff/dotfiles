# Home-manager half of the Android host: everything the old
# hosts/android/.bashrc and the setup_bash / setup_git / setup_shortcuts /
# setup_termux functions of setup.sh used to do imperatively.
{
  pkgs,
  lib,
  paths,
  commands,
  ...
}:

let
  # Written into ~/.bashrc verbatim rather than via home.sessionVariables,
  # because $(date +%Y) has to be evaluated by the shell, not by Nix, and
  # session variables must not depend on each other.
  #
  # Same names as the old .bashrc (FINANCE_PATH / TIME_PATH), which differ
  # from the desktop's LEDGER_PATH / TIMEDOT_PATH on purpose.
  envVars = ''
    export NOTES_DIR="${paths.notesDir}"

    export FINANCE_PATH="$NOTES_DIR/Journal/_finance"
    export LEDGER_FILE="$FINANCE_PATH/private/$(date +%Y).hledger"
    export LEDGER_ALL_FILE="$FINANCE_PATH/all.hledger"

    export TIME_PATH="$NOTES_DIR/Journal/_time"
    export TIMEDOT_FILE="$TIME_PATH/$(date +%Y).timedot"
    export TIMEDOT_ALL_FILE="$TIME_PATH/all.journal"
    export TIMEDOT_SEMESTER_FILE="$TIME_PATH/${paths.semesterTimedot}"
    export TIMEDOT_WORK_FILE="$TIME_PATH/work/$(date +%Y).timeclock"

    export DOTFILES_PATH="${paths.dotfilesDir}"
  '';

  # The old hosts/android/shortcuts/* scripts. They are kept because they are
  # also perfectly good standalone launchers, but be aware that the widget
  # itself does not work under nix-on-droid: Termux plugin apps bind to the
  # com.termux package id and this app is com.termux.nix. See ./README.md.
  shortcuts = {
    inherit (commands)
      clkin
      clkout
      tda
      tdauni
      ;
  };

  shortcutFiles = lib.mapAttrs' (
    name: pkg:
    lib.nameValuePair ".shortcuts/${name}" {
      source = lib.getExe' pkg name;
      executable = true;
    }
  ) shortcuts;
in
{
  home.stateVersion = "24.05";

  # No $(date) here on purpose: these are static and are wanted by
  # non-interactive shells too.
  home.sessionVariables = {
    EDITOR = "nvim";
    FZF_DEFAULT_COMMAND = "fd";
  };

  programs.bash = {
    enable = true;

    # bashrcExtra lands before home-manager's `[[ $- == *i* ]] || return`
    # guard, so a script that sources ~/.bashrc still gets the paths.
    bashrcExtra = envVars;

    shellAliases = {
      hl = "hledger";
      hla = "hledger -f \"$LEDGER_ALL_FILE\"";
      hle = "nvim \"$LEDGER_FILE\"";

      td = "hledger -f \"$TIMEDOT_ALL_FILE\"";
      timedot = "hledger -f \"$TIMEDOT_FILE\"";

      nv = "nvim";
      pulldots = "(cd \"$DOTFILES_PATH\" && git pull)";
    };
  };

  # tda, tdauni, tdawork, clkin, clkout, bknotes and bkinit used to be shell
  # functions and aliases in .bashrc. They are executables now, installed via
  # environment.packages in ./default.nix, so shortcuts and `sh -c` reach them
  # too. See ./commands.nix.

  programs.git = {
    enable = true;
    # No commit signing: op-ssh-sign from ../../modules/git.nix needs the
    # 1Password desktop app, which does not exist here.
    settings = {
      user = {
        name = "bitSheriff";
        email = "root@bitsheriff.dev";
      };
      core.editor = "nvim";
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true;
      # The notes live on the Android FUSE mount, which reports a foreign
      # owner. Without this git refuses to touch the repository.
      safe.directory = paths.notesDir;
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # hledger.conf, same content as the desktop
  # (../../modules/hledger/default.nix).
  xdg.configFile."hledger/hledger.conf".text = ''
    [check] --strict
    [balancesheet] --layout=bare
  '';

  home.file = {
    # Extra keys row, bell and margins. Read by the app itself. The old
    # setup_termux ran `termux-reload-settings` here; that command is part of
    # android-integration, which cannot be built (see ./default.nix), so a
    # change to this file needs the session restarted instead.
    ".termux/termux.properties".source = ./termux.properties;
  }
  // shortcutFiles;
}
