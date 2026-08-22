# nix-on-droid configuration for the Pixel.
#
# This is deliberately NOT the desktop config in miniature. nix-on-droid has
# no NixOS module system, no systemd and no display server, so ../../modules
# cannot be imported here. What is shared is the part that matters: the
# hledger/timedot scripts in ../../modules/hledger/scripts.nix, which are
# plain derivations for exactly that reason.
#
# Everything the old hosts/android/setup.sh did imperatively (packages,
# .bashrc, termux.properties, git config, shortcuts) is declared here or in
# ./home.nix. setup.sh is now only the bootstrap that gets Nix to this point.
{ pkgs, ... }:

let
  paths = import ./paths.nix;
  commands = import ./commands.nix { inherit pkgs paths; };
in
{
  # The Termux replacements. Plugin apps (Termux:API, Termux:Widget) cannot
  # attach to nix-on-droid because it ships under a different package id, so
  # these wrappers are the whole of the Android integration that is available.
  android-integration = {
    am.enable = true; # launch Android activities from the shell
    termux-open.enable = true; # open a file with an Android app
    termux-open-url.enable = true;
    termux-reload-settings.enable = true; # apply ./termux.properties
    termux-setup-storage.enable = true; # create ~/storage/*
    termux-wake-lock.enable = true; # keep long git pulls alive
    termux-wake-unlock.enable = true;
    xdg-open.enable = true;
  };

  environment.packages =
    (with pkgs; [
      # The bootstrap ships almost nothing, so the usual userland comes first.
      coreutils
      findutils
      diffutils
      gnugrep
      gnused
      gnutar
      gawk
      procps
      psmisc
      hostname
      which
      less
      man
      ncurses # terminfo, without it hledger-ui/nvim/fzf misbehave
      cacert
      git

      # The tools the old setup.sh installed with `pkg install`.
      # fzf is missing on purpose: home-manager installs it, because it also
      # writes its config (./home.nix).
      # termux-api is gone for good, see the android-integration note above.
      fd
      gum
      inetutils # ping, telnet and friends
      neovim
      openssh

      # hledger itself. Every one of these has an aarch64-linux build in
      # cache.nixos.org, so the phone never has to compile Haskell.
      hledger
    ])
    ++ (with commands; [
      # Shared with the desktop.
      hl-accounts
      timedot-add
      timeclock-add
      # Android-specific wrappers, real executables rather than shell aliases
      # so they also work from a shortcut. See ./commands.nix.
      tda
      tdauni
      tdawork
      clkin
      clkout
      bknotes
      bkinit
      dots-switch
    ]);

  # Ask for the storage permission on first activation. The app pops the
  # Android dialog; once granted it symlinks ~/storage/documents and friends.
  # Guarded so a declined permission cannot fail the whole switch.
  build.activationAfter.storage = ''
    if [ ! -d "${paths.storageDir}" ]; then
      echo "Requesting Android storage permission (needed for ${paths.notesDir})"
      # termux-tools is internal to nix-on-droid rather than an attribute of
      # pkgs, so this goes through PATH. On the very first switch the command
      # is not there yet and ./setup.sh handles it instead.
      if command -v termux-setup-storage >/dev/null 2>&1; then
        $DRY_RUN_CMD termux-setup-storage || true
      fi
    fi
  '';

  # The bootstrap seeds this in ~/.config/nix/nix.conf (see ./setup.sh); from
  # the first successful switch on, it is declared here.
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Europe/Vienna";

  # Keep a .bak of anything already in /etc so activation cannot fail on a
  # file the bootstrap wrote.
  environment.etcBackupExtension = ".nod-bak";

  # The stock welcome banner on every new session gets old fast.
  environment.motd = null;

  # gum, fzf and neovim all draw glyphs the stock terminal font has no idea
  # about; same font as the desktop (../../collections/office.nix).
  terminal.font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf";

  user.shell = "${pkgs.bashInteractive}/bin/bash";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit paths commands; };
    config = ./home.nix;
  };

  system.stateVersion = "24.05";
}
