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
  # All of android-integration is off, and it is not a matter of taste.
  #
  # Every one of these options pulls in a package that has to be compiled on
  # the phone -- none of the eight are in cache.nixos.org or in
  # nix-on-droid.cachix.org -- and compiling them fails in unpackPhase under
  # proot:
  #
  #   cp: setting permissions for 'source': No such file or directory
  #   do not know how to unpack source archive /nix/store/...-source
  #
  # https://github.com/nix-community/nix-on-droid/issues/480, open since
  # October 2025. Re-enable once that is fixed; nothing else here depends on
  # it. Until then:
  #   * storage permission -> Android settings, see build.activationAfter below
  #   * wake lock          -> the app's own notification
  #   * termux.properties  -> restart the session instead of reloading
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

  # Nag about the storage permission, because without ~/storage there are no
  # notes and every hledger command below is pointless.
  #
  # This cannot request the permission itself while android-integration is
  # disabled (see above), so it points at the toggle instead. Granting it in
  # the app settings is what creates ~/storage/documents and friends -- the
  # termux-setup-storage command only ever triggered the same dialog.
  build.activationAfter.storage = ''
    if [ ! -d "${paths.storageDir}" ]; then
      echo "No ${paths.storageDir} yet, so ${paths.notesDir} cannot exist."
      echo "Grant storage access: Android settings -> Apps -> Nix-on-Droid"
      echo "-> Permissions -> Files, then restart the app."
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
