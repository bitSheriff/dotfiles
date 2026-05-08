{
  config,
  pkgs,
  activeUsers,
  ...
}:
let
  sync_resolve = pkgs.writeShellScriptBin "sync-resolve" ''
    FD="${pkgs.fd}/bin/fd"
      MELD="${pkgs.meld}/bin/meld"

      # We use fd to find conflicts and loop through them
      $FD ".sync-conflict-" . --type f | while read -r conflict_file; do

        # Extract the original filename
        original_file=$(echo "$conflict_file" | sed -E 's/\.sync-conflict-[0-9]{8}-[0-9]{6}-[A-Z0-9]+(\.[^.]+)?$/\1/')

        if [ -f "$original_file" ]; then
          echo "------------------------------------------------"
          echo "Conflict found: $conflict_file"
          # Open Meld. Script pauses here until Meld is closed.
          $MELD "$original_file" "$conflict_file"

          echo -n "Delete conflict file? [y/N] "
          read -r confirm < /dev/tty

          if [[ "$confirm" =~ ^[yY]$ ]]; then
            rm "$conflict_file"
            echo "✓ Deleted."
          else
            echo "○ Kept."
          fi
        else
          echo "------------------------------------------------"
          echo "⚠ Warning: Original file not found for: $conflict_file"
        fi
      done

      echo "------------------------------------------------"
      echo "Process complete."
  '';
in
{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
    sync_resolve
  ];

  services.syncthing = {
    enable = true;
    user = "benjamin";
    dataDir = "/home/benjamin/.config/syncthing";
    configDir = "/home/benjamin/.config/syncthing";
  };

  networking.hosts = {
    "127.0.0.1" = [ "syncthing.local" ];
  };

  services.nginx = {
    virtualHosts."syncthing.local" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 80;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:8384";
        proxyWebsockets = true;
      };
    };
  };

}
