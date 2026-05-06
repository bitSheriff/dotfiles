{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:
let
  digest-mp3s =
    pkgs.writers.writePython3Bin "digest-mp3s"
      {
        flakeIgnore = [
          "E501"
          "E302"
          "E226"
          "E305"
        ];
      }
      ''
        import os
        import sys
        import json
        import subprocess
        import shutil
        import re
        from pathlib import Path

        # Nix will inject the absolute paths to these binaries in the store!
        FFPROBE = "${pkgs.ffmpeg}/bin/ffprobe"
        TREE = "${pkgs.tree}/bin/tree"

        def sanitize_name(name):
            if not name:
                return "Unknown"
            safe = re.sub(r'[\\/*?:"<>|]', '_', name)
            return safe.strip() or "Unknown"

        def get_metadata(filepath):
            cmd = [
                FFPROBE, "-v", "quiet", "-print_format", "json",
                "-show_format", str(filepath)
            ]
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, check=True)
                data = json.loads(result.stdout)
                tags = data.get("format", {}).get("tags", {})
                return {k.lower(): v for k, v in tags.items()}
            except (subprocess.CalledProcessError, json.JSONDecodeError):
                return {}

        def digest_mp3s(source_dir, dest_dir):
            source_path = Path(source_dir)
            dest_path = Path(dest_dir)

            mp3_files = list(source_path.rglob("*.mp3"))

            if not mp3_files:
                print(f"No MP3 files found in {source_dir}")
                return

            print(f"Found {len(mp3_files)} MP3 files. Digesting...\n")

            for filepath in mp3_files:
                tags = get_metadata(filepath)

                artist_raw = tags.get("album_artist") or tags.get("album artist")
                if not artist_raw:
                    artist_raw = tags.get("artist", "Unknown Artist")

                artist = re.split(r'[/;]', artist_raw)[0].strip()
                album = tags.get("album", "Unknown Album")

                safe_artist = sanitize_name(artist)
                safe_album = sanitize_name(album)

                target_dir = dest_path / safe_artist / safe_album
                target_dir.mkdir(parents=True, exist_ok=True)

                target_file = target_dir / filepath.name

                if not target_file.exists():
                    print(f"Moving: '{filepath.name}' -> {safe_artist}/{safe_album}/")
                    shutil.move(str(filepath), str(target_file))
                else:
                    print(f"Skipping: '{filepath.name}' (already exists in destination)")

            print("\n" + "="*40)
            print("Digestion Complete! Here is your library:")
            print("="*40)

            subprocess.run([TREE, "-d", "-L", "2", str(dest_path)])

        if __name__ == "__main__":
            if len(sys.argv) != 3:
                print("Usage: digest-mp3s <source_directory> <destination_directory>")
                sys.exit(1)

            src = sys.argv[1]
            dst = sys.argv[2]

            if not os.path.isdir(src):
                print(f"Error: Source directory '{src}' does not exist.")
                sys.exit(1)

            digest_mp3s(src, dst)
      '';
in

{

  imports = [
    ../modules/mpv
    ../modules/mpd.nix
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  environment.systemPackages =
    with pkgs;
    [
      # Image & Graphics
      gimp # like photoshop but without selling your soul
      inkscape
      ente-desktop # encrypted photo backup
      qview # minimal image viewer
      imagemagick # i think there is nothing it cannot do

      # Video & Recording
      vlc

      # Audio
      pavucontrol
      spotify
      audacity # audio editor
      picard # mp3tag editor
      feishin # jellyfin and navidrone music player (spotify alike)
      # asunder # ripping cd's like its 2000
      digest-mp3s
    ]

    # Host Specifics
    ++ lib.optionals (config.networking.hostName == "rhodos") [
      fladder
    ]

    # User Specifics - benjamin only
    ++ lib.optionals (lib.elem "benjamin" activeUsers) [
      kew # terminal music player
      musikcube # another terminal music player
    ];

  services.tumbler.enable = true; # image thumbnails
}
