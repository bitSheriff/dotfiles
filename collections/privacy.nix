{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.cfg.privacy.enable {
    environment.systemPackages =
      with pkgs;
      [
        mullvad-vpn
        mat2 # remove metadata from files
      ]
      ++ lib.optionals config.cfg.privacy.tor.enable [
        tor
        tor-browser
        onionshare # share files over tor
      ]
      ++ lib.optionals config.cfg.privacy.cryptocurrency.enable [
        ledger-live-desktop

      ];

    security.apparmor = {
      enable = true;
      packages = [ pkgs.apparmor-profiles ];
    };

    services.mullvad-vpn.enable = true;

    # Advanced Kernel Hardening (does not work with nvidia)
    # boot.kernel.sysctl = {
    #   # Restrict dmesg access to root to prevent info leaks
    #   "kernel.dmesg_restrict" = 1;
    #   # Restrict eBPF to root to mitigate many side-channel attacks
    #   "kernel.unprivileged_bpf_disabled" = 1;
    #   # Prevent unprivileged users from viewing kernel addresses in /proc
    #   "kernel.kptr_restrict" = 2;
    # };
  };
}
