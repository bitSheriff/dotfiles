{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  config = lib.mkIf config.cfg.browser.chromium.enable {
    environment.systemPackages = with pkgs; [
      chromium
    ];
  };
}
