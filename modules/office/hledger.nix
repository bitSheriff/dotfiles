{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    hledger
    hledger-ui
    hledger-web
    hledger-iadd
  ];

  home-manager.users.benjamin = {
    home.sessionVariables = {
      LEDGER_PATH = "$HOME/notes/Journal/_finance";
      LEDGER_FILE = "$HOME/notes/Journal/_finance/2026.hledger";
      LEDGER_ALL_FILE = "$HOME/notes/Journal/_finance/all.hledger";
      LEDGER_TEMPLATE_FILE = "$HOME/notes/Journal/_finance/templates.hledger";
      TIMEDOT_PATH = "$HOME/notes/Journal/_time";
      TIMEDOT_ALL_FILE = "$HOME/notes/Journal/_time/all.journal";
      TIMEDOT_SEMESTER_FILE = "$HOME/notes/Journal/_time/uni/2026SS.timedot";
    };

    # For variables that need shell evaluation like $(date +%Y)
    programs.zsh.envExtra = ''
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

    xdg.configFile."hledger/hledger.conf".text = ''
      [check] --strict
      [balancesheet] --layout=bare
    '';
  };
}
