# overlays/default.nix
inputs: final: prev: {
  # Signal TUI client
  siggy = final.callPackage ./siggy.nix { };

  # git-today recaps your daily git work
  git-today = inputs.git-today.packages.${final.stdenv.hostPlatform.system}.default;

  # supernote-tool for Ratta Supernote
  supernote-tool = final.python3Packages.callPackage ./supernote-tool.nix { };

  # marktext markdown editor. nixpkgs tracks the develop branch but lags far
  # behind (snapshot 2025-11-19), and there is no recent stable release. Pin to
  # the upstream v0.20.0-rc.1 prebuilt AppImage instead. Bump url+hash in
  # ./marktext.nix to update; see its `version`.
  marktext = final.callPackage ./marktext.nix { };

  # LSP server for hledger journal files, not (yet) in nixpkgs
  hledger-lsp = final.callPackage ./hledger-lsp.nix { };

  # Extra Kodi addons not (yet) packaged in nixpkgs' kodiPackages
  kodiPackages = prev.kodiPackages // {
    pyxbmct = prev.kodiPackages.callPackage ./kodi-addons/pyxbmct.nix { };
    tubed-api = prev.kodiPackages.callPackage ./kodi-addons/tubed-api.nix { };
    tubed = prev.kodiPackages.callPackage ./kodi-addons/tubed.nix {
      pyxbmct = prev.kodiPackages.callPackage ./kodi-addons/pyxbmct.nix { };
      tubed-api = prev.kodiPackages.callPackage ./kodi-addons/tubed-api.nix { };
    };
  };

  # Enable RAR decompression support (RAR is unfree)
  ouch = prev.ouch.override { enableUnfree = true; };

  varia = prev.varia.overridePythonAttrs (old: {
    # Fix missing dbus-next dependency for varia's tray icon
    dependencies = (old.dependencies or [ ]) ++ [ final.python3Packages.dbus-next ];

    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/variamain.py \
        --replace-fail '"--rpc-listen-port=6801",' \
                       '"--rpc-listen-port=6801", "--rpc-allow-origin-all",'
    '';
  });

}
