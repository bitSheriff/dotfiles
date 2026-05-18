{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  nb = pkgs.writeShellScriptBin "nb" ''
    nix build "$@" |& nom
  '';

  nd = pkgs.writeShellScriptBin "nd" ''
    nix develop --impure
  '';
in
{
  environment.systemPackages = with pkgs; [
    agenix-cli # needed for age to encrypt nix
    nh # nix cli helper
    agenix-cli # needed for age to encrypt nix
    nix-update # update helper for overlays
    nix-output-monitor # better show output (useful for nix build |& nom)
    # scripts
    nb
    nd
  ];

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];
  };

  environment.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1"; # needed for packages installed with nix-shell
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = 2; # Only build 2 things at once
      cores = 4; # Only use 4 cores per build
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [
        "root"
        "@wheel"
      ];

      substituters = [
        # not stable enough if device is offline
        # "ssh://benjamin@delos"
        # "ssh://benjamin@rhodos"
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = [
        "local-network-cache:bGwTUJA5yO+yGUXDXFnqPz5hvaUtlW4VnHt9k8uxMOU="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    # keeps your drive from filling up with old generations
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # de-duplicating the remaining files
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    # be able to build offline
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # notify about the changes of nixos-rebuild
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
           /run/current-system "$systemConfig"
    '';
  };

}
