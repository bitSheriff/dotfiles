{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tor
    tor-browser
    mullvad-vpn
    onionshare # share files over tor
    mat2 # remove metadata from files
  ];

  security.apparmor = {
    enable = true;
    packages = [ pkgs.apparmor-profiles ];
  };

  # Advanced Kernel Hardening (does not work with nvidia)
  # boot.kernel.sysctl = {
  #   # Restrict dmesg access to root to prevent info leaks
  #   "kernel.dmesg_restrict" = 1;
  #   # Restrict eBPF to root to mitigate many side-channel attacks
  #   "kernel.unprivileged_bpf_disabled" = 1;
  #   # Prevent unprivileged users from viewing kernel addresses in /proc
  #   "kernel.kptr_restrict" = 2;
  # };
}
