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
  # The Termux replacements. None of these eight are in any binary cache, so
  # they are compiled on the phone, which used to fail in unpackPhase:
  #
  #   cp: setting permissions for 'source': No such file or directory
  #   do not know how to unpack source archive /nix/store/...-source
  #
  # That is https://github.com/nix-community/nix-on-droid/issues/480, and it
  # looks like the same class of bug as #495: proot mistranslating a syscall.
  # Re-enabled now that the patched proot from
  # https://github.com/nix-community/nix-on-droid/pull/529 is live -- see the
  # proot note in ./README.md, the app's bundled one is too old and has to be
  # swapped in by hand.
  #
  # termux-setup-storage is the one that actually matters: granting the storage
  # permission in Android settings does NOT create ~/storage. The symlinks come
  # from the app's setupStorageSymlinks(), which only runs when the permission
  # is requested through the app's own flow, and this command is what triggers
  # that.
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

  # Create ~/storage, because without it there are no notes and every hledger
  # command above is pointless.
  #
  # termux-setup-storage does the work, and it has to: the Android permission
  # toggle alone grants access but never creates the symlinks (see the
  # android-integration note). Guarded so a declined dialog cannot fail the
  # switch, and only run when ~/storage is actually missing.
  build.activationAfter.storage = ''
    if [ ! -d "${paths.storageDir}" ]; then
      echo "Requesting Android storage permission (needed for ${paths.notesDir})"
      $DRY_RUN_CMD termux-setup-storage || true
      if [ ! -d "${paths.storageDir}" ]; then
        echo "Still no ${paths.storageDir}. Accept the dialog, or run"
        echo "termux-setup-storage by hand once this switch has finished."
      fi
    fi
  '';

  # The bootstrap seeds this in ~/.config/nix/nix.conf (see ./setup.sh); from
  # the first successful switch on, it is declared here.
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # proot-static is cross-compiled for Android and is never in cache.nixos.org
  # -- nix-on-droid's own cache is the only place it exists prebuilt, and the
  # phone cannot build it. Stated explicitly so a fresh bootstrap cannot end up
  # without it.
  nix.substituters = [
    "https://cache.nixos.org"
    "https://nix-on-droid.cachix.org"
  ];
  nix.trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
  ];

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
