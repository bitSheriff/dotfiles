{
  config,
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    # Container
    docker
    docker-compose
    lazydocker # makes docker less pain in the ass

    # Distro Box
    distrobox
    distroshelf # gui for distrobox

    # Virtual Machines
    qemu
    gnome-boxes

  ];

  ## Docker
  virtualisation.docker.enable = true;
  users.users.benjamin.extraGroups = [
    "docker"
    "libvirtd"
  ];

  # mainly used for distrobox
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Set to false to avoid conflict with actual Docker
    defaultNetwork.settings.dns_enabled = true;

    # Auto-delete old unused images/containers to keep NixOS clean
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  # Force Distrobox to use Podman
  environment.sessionVariables = {
    DISTROBOX_ENGINE = "podman";
  };

  ## Libvirt
  virtualisation.libvirtd.enable = true;
  # Enable TPM emulation (optional)
  virtualisation.libvirtd.qemu = {
    swtpm.enable = true;
  };

  # Enable USB redirection (optional)
  virtualisation.spiceUSBRedirection.enable = true;

}
