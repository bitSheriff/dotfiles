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

  varia = prev.varia.overridePythonAttrs (old: {
    # Fix missing dbus-next dependency for varia's tray icon
    dependencies = (old.dependencies or [ ]) ++ [ final.python3Packages.dbus-next ];

    # Let the Varia Integrator browser extension reach aria2's RPC.
    #
    # The extension POSTs to http://127.0.0.1:6801/jsonrpc with
    # Content-Type: application/json, which forces a CORS preflight. aria2
    # answers preflights with no Access-Control-* headers unless told to, so
    # the fetch fails, the extension's catch swallows it, and Firefox keeps
    # downloading the file itself.
    #
    # Normally the extension's <all_urls> host permission would make Firefox
    # skip CORS entirely, but the AMO build (1.5.6) is manifest v3 and still
    # declares <all_urls> under "permissions" instead of "host_permissions".
    # Firefox's manifest schema only accepts match patterns in "permissions"
    # for manifest v2, so it drops <all_urls> on load: the extension ends up
    # with no host permissions and none to grant in about:addons.
    # Upstream's manifest-firefox.json is still v2 and unaffected.
    #
    # Opening up CORS on the RPC is the remaining fix. aria2 only listens on
    # loopback here, and the RPC carries no secret, so this changes nothing
    # an existing local process could not already do.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/variamain.py \
        --replace-fail '"--rpc-listen-port=6801",' \
                       '"--rpc-listen-port=6801", "--rpc-allow-origin-all",'
    '';
  });

}
