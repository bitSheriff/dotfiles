# Paths and constants shared by ./default.nix, ./home.nix and ./commands.nix.
#
# nix-on-droid ships as a separate app from Termux, so the prefix is
# com.termux.nix rather than com.termux. Everything below is derived from
# that, which is why the old hard-coded /data/data/com.termux/... paths in the
# previous .bashrc had to move here.
rec {
  # Read-only in nix-on-droid as `config.user.home`; spelled out because
  # ./commands.nix has no module system to read it from.
  homeDir = "/data/data/com.termux.nix/files/home";

  # Created by termux-setup-storage (the app symlinks DIRECTORY_DOCUMENTS
  # here once the storage permission is granted).
  storageDir = "${homeDir}/storage";
  notesDir = "${storageDir}/documents/notes";

  financePath = "${notesDir}/Journal/_finance";
  timePath = "${notesDir}/Journal/_time";

  # The semester file cannot be derived from the date, same as on the desktop.
  semesterTimedot = "uni/2026SS.timedot";

  # Forgejo box on the home network.
  backupHost = "10.0.0.151";
  backupPort = 2222;
  backupRemote = "ssh://git@${backupHost}:${toString backupPort}/bitSheriff/notes.git";

  dotfilesDir = "${homeDir}/code/dotfiles";

  # Attribute name under nixOnDroidConfigurations in the flake.
  configName = "android";
}
