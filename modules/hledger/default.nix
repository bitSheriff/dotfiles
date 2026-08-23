{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

let
  # The scripts themselves live in ./scripts.nix so the nix-on-droid host
  # (../../hosts/android) can reuse them without the NixOS module system.
  scripts = import ./scripts.nix { inherit pkgs; };
in
{
  environment.systemPackages =
    (with pkgs; [
      hledger
      hledger-ui
      hledger-web
      hledger-iadd
      pricehist # fetch stock and crypto prices
    ])
    ++ (with scripts; [
      # own scripts
      hl-accounts
      timeclock-add
      timeclock-timer
      timedot-add
      hl-update-prices
    ]);

  # Use interactiveShellInit for all variables to ensure they are available in the shell
  # and properly expanded with $HOME and $(date).
  programs.zsh.interactiveShellInit = ''
    export LEDGER_PATH="$HOME/notes/Journal/_finance"
    export LEDGER_FILE="$LEDGER_PATH/private/2026.hledger"
    export LEDGER_ALL_FILE="$LEDGER_PATH/all.hledger"
    export LEDGER_TEMPLATE_FILE="$LEDGER_PATH/templates.hledger"

    export TIMEDOT_PATH="$HOME/notes/Journal/_time"
    export TIMEDOT_ALL_FILE="$TIMEDOT_PATH/all.journal"
    export TIMEDOT_SEMESTER_FILE="$TIMEDOT_PATH/uni/2026SS.timedot"
    export TIMEDOT_SEMESTER_CLOCK_FILE="$TIMEDOT_PATH/uni/2026SS.timeclock"

    export LEDGER_ACCOUNTS_FILE="$LEDGER_PATH/$(date +%Y)_accounts.hledger"
    export TIMEDOT_FILE="$TIMEDOT_PATH/$(date +%Y).timedot"
    export TIMEDOT_WORK_FILE="$TIMEDOT_PATH/work/$(date +%Y).timeclock"
  '';

  programs.zsh.shellAliases = {
    hl = "hledger";
    hla = "hledger -f \${LEDGER_ALL_FILE}";
    hlae = "(cd $LEDGER_PATH && nvim $(fd . --type f -E .stversions -e hledger | fzf))";

    hla-gain = "hledger -f \${LEDGER_ALL_FILE} bs --gain --value=now,EUR";
    hl-budget = "hledger bal expenses --budget";
    hl-temp = "hledger-templates";
    hle = "nv \${LEDGER_FILE}";

    td = "hledger -f \${TIMEDOT_ALL_FILE}";
    tde = "(cd $TIMEDOT_PATH && nvim $(fd -t f -e timedot -e timeclock -E .stversions | fzf))";
    tda = "timedot-add \${TIMEDOT_FILE}";
    clkin = "FILE=$(fd . \"\${TIMEDOT_PATH}\" --extension=timeclock --type f | fzf) && [ -n \"\$FILE\" ] && timeclock-add \"\$FILE\" i";
    clkout = "FILE=$(fd . \"\${TIMEDOT_PATH}\" --extension=timeclock --type f | fzf) && [ -n \"\$FILE\" ] && timeclock-add \"\$FILE\" o";
    clktimer = "FILE=$(fd . \"\${TIMEDOT_PATH}\" --extension=timeclock --type f | fzf) && [ -n \"\$FILE\" ] && timeclock-timer \"\$FILE\"";

    # Uni
    tdauni = "timedot-add \${TIMEDOT_SEMESTER_FILE}";
    uniin = "timeclock-add \${TIMEDOT_SEMESTER_CLOCK_FILE} i";
    uniout = "timeclock-add \${TIMEDOT_SEMESTER_CLOCK_FILE} o";

    # Work
    tdawork = "timeclock-add \${TIMEDOT_WORK_FILE}";
    clockin = "timeclock-add \${TIMEDOT_WORK_FILE} i";
    clockout = "timeclock-add \${TIMEDOT_WORK_FILE} o";
  };

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    xdg.configFile."hledger/hledger.conf".text = ''
      [check] --strict
      [balancesheet] --layout=bare
    '';
  };
}
