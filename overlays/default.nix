# overlays/default.nix
inputs: final: prev: {
  # Signal TUI client
  siggy = final.callPackage ./siggy.nix { };

  # git-today recaps your daily git work
  git-today = inputs.git-today.packages.${final.stdenv.hostPlatform.system}.default;

  # supernote-tool for Ratta Supernote
  supernote-tool = final.python3Packages.callPackage ./supernote-tool.nix { };

  # nixpkgs bumped glaze 7.9.1 -> 8.0.0 (PR #548864, 2026-08-04), but hyprland
  # 0.56.1 requires glaze in range `7...<8`. With glaze 8, find_package fails and
  # hyprland tries to FetchContent-clone glaze over the network, which the build
  # sandbox blocks. Pin hyprland to the previous glaze (7.9.1).
  # Remove once nixpkgs ships a hyprland that supports glaze 8.
  hyprland = prev.hyprland.override {
    glaze = prev.glaze.overrideAttrs (old: {
      version = "7.9.1";
      src = final.fetchFromGitHub {
        owner = "stephenberry";
        repo = "glaze";
        tag = "v7.9.1";
        hash = "sha256-NRRq5MGF2f5PW0teYnq58ELzson+U6KHVPaY6r30KLA=";
      };
    });
  };
}
