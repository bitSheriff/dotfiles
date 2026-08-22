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
  # All of android-integration stays off. None of these eight are in any binary
  # cache, so they get compiled on the phone, and that fails in unpackPhase:
  #
  #   cp: setting permissions for 'source': No such file or directory
  #   do not know how to unpack source archive /nix/store/...-source
  #
  # https://github.com/nix-community/nix-on-droid/issues/480. Retested with the
  # patched proot from PR #529 live (the one that fixed the activation hang,
  # see ./README.md) and it fails identically, so despite the resemblance this
  # is NOT the same syscall bug -- it is its own problem, still open.
  #
  # The only one worth having was termux-setup-storage, and
  # build.activationAfter.storage below replaces it outright, so nothing here
  # is load-bearing any more. What is lost:
  #   * wake lock          -> the app's own notification
  #   * termux.properties  -> restart the session instead of reloading
  #   * am / termux-open / xdg-open -> no opening files in Android apps
  #
  # android-integration = {
  #   am.enable = true;
  #   termux-open.enable = true;
  #   termux-open-url.enable = true;
  #   termux-reload-settings.enable = true;
  #   termux-setup-storage.enable = true;
  #   termux-wake-lock.enable = true;
  #   termux-wake-unlock.enable = true;
  #   xdg-open.enable = true;
  # };

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

      fd
      gum
      inetutils # ping, telnet and friends
      neovim
      openssh
      just

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

  # Create ~/storage ourselves, standing in for termux-setup-storage, which
  # cannot be built (see the android-integration note above).
  #
  # That command was never doing anything clever: it broadcasts an intent that
  # makes the app run TermuxInstaller.setupStorageSymlinks(), which symlinks a
  # handful of well-known directories out of /storage/emulated/0. The names and
  # targets below are exactly the set that function creates. Granting the
  # storage permission is still a manual step -- Android settings -> Apps ->
  # Nix-on-Droid -> Permissions -> Files -- but once granted, this session runs
  # as the app's uid and can make the links itself.
  # Every link is re-asserted on each switch rather than only when
  # ${paths.storageDir} is missing. ln -sfn and mkdir -p are idempotent, so the
  # cost is nothing, and a link added to this list later actually appears
  # instead of waiting for a phone that no longer has a first run.
  build.activationAfter.storage = ''
    # /sdcard is a symlink to the same place on every current Android, but
    # proot does not always expose both.
    root=""
    for candidate in /storage/emulated/0 /sdcard; do
      if [ -d "$candidate" ]; then
        root="$candidate"
        break
      fi
    done

    if [ -z "$root" ]; then
      echo "Shared storage is not visible from here, so ${paths.storageDir} cannot be created."
      echo "Grant it in Android settings -> Apps -> Nix-on-Droid -> Permissions -> Files,"
      echo "restart the app, then run: nix-on-droid switch --flake <flake>#${paths.configName}"
    else
      [ -d "${paths.storageDir}" ] || echo "Linking ${paths.storageDir} to $root"

      $DRY_RUN_CMD mkdir -p "${paths.storageDir}"
      $DRY_RUN_CMD ln -sfn "$root" "${paths.storageDir}/shared"
      $DRY_RUN_CMD ln -sfn "$root/Documents" "${paths.storageDir}/documents"
      $DRY_RUN_CMD ln -sfn "$root/Download" "${paths.storageDir}/downloads"
      $DRY_RUN_CMD ln -sfn "$root/DCIM" "${paths.storageDir}/dcim"
      $DRY_RUN_CMD ln -sfn "$root/Pictures" "${paths.storageDir}/pictures"
      $DRY_RUN_CMD ln -sfn "$root/Music" "${paths.storageDir}/music"
      $DRY_RUN_CMD ln -sfn "$root/Movies" "${paths.storageDir}/movies"

      # The Obsidian vault, one hop from $HOME instead of three. Points at
      # ${paths.notesDir} rather than at $root directly, so it follows
      # notesDir in ./paths.nix if that ever moves.
      $DRY_RUN_CMD ln -sfn "${paths.notesDir}" "${paths.notesLink}"

      if [ ! -e "${paths.notesLink}/" ]; then
        echo "Note: ${paths.notesLink} is a dangling link, ${paths.notesDir} does not exist yet."
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
