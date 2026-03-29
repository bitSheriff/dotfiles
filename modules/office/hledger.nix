{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    hledger
    hledger-ui
    hledger-web
    hledger-iadd
  ];

  # Use interactiveShellInit for all variables to ensure they are available in the shell
  # and properly expanded with $HOME and $(date).
  programs.zsh.interactiveShellInit = ''
    export LEDGER_PATH="$HOME/notes/Journal/_finance"
    export LEDGER_FILE="$LEDGER_PATH/2026.hledger"
    export LEDGER_ALL_FILE="$LEDGER_PATH/all.hledger"
    export LEDGER_TEMPLATE_FILE="$LEDGER_PATH/templates.hledger"
    export TIMEDOT_PATH="$HOME/notes/Journal/_time"
    export TIMEDOT_ALL_FILE="$TIMEDOT_PATH/all.journal"
    export TIMEDOT_SEMESTER_FILE="$TIMEDOT_PATH/uni/2026SS.timedot"

    export LEDGER_ACCOUNTS_FILE="$LEDGER_PATH/$(date +%Y)_accounts.hledger"
    export TIMEDOT_FILE="$TIMEDOT_PATH/$(date +%Y).timedot"
    export TIMEDOT_WORK_FILE="$TIMEDOT_PATH/work/$(date +%Y).timeclock"
  '';

  programs.zsh.shellAliases = {
    hl = "hledger";
    hla = "hledger -f \${LEDGER_ALL_FILE}";
    hl-budget = "hledger bal expenses --budget";
    hl-temp = "hledger-templates";
    hle = "nv \${LEDGER_FILE}";

    td = "hledger -f \${TIMEDOT_ALL_FILE}";
    tda = "timedot-add \${TIMEDOT_FILE}";
    tdauni = "timedot-add \${TIMEDOT_SEMESTER_FILE}";
    tdawork = "timeclock-add \${TIMEDOT_WORK_FILE}";
    clockin = "timeclock-add \${TIMEDOT_WORK_FILE} i";
    clockout = "timeclock-add \${TIMEDOT_WORK_FILE} o";
  };

  home-manager.users.benjamin = {
    xdg.configFile."hledger/hledger.conf".text = ''
      [check] --strict
      [balancesheet] --layout=bare
    '';
  };
}
