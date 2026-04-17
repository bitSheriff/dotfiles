{
  config,
  pkgs,
  inputs,
  username,
  ...
}:

{

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
}
