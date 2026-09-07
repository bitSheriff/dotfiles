{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.cfg.modules.latex.enable {
    environment.systemPackages = with pkgs; [
      texliveMedium
      # texliveFull

    ];
  };
}
