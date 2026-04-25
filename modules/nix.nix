{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    agenix-cli # needed for age to encrypt nix
    nh # nix cli helper
    agenix-cli # needed for age to encrypt nix
    nix-update # update helper for overlays
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
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [
        "root"
        "@wheel"
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
