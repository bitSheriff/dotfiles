{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:
let
  # 1. Distro Container Configuration
  distroboxSet = {
    # Ubuntu Matlab
    # has everything to install and run Matlab
    ubuntu-matlab = {
      image = "docker.io/library/ubuntu:latest";
      additional_packages = "libxft2 libxrender1 libxtst6 libxi6 openjdk-25-jdk eza zoxide";
      init = false;
      nvidia = true;
      pull = true;
      replace = true;
    };
  };

  # generate the INI file
  distroboxIni = pkgs.writeText "distrobox.ini" (lib.generators.toINI { } distroboxSet);

  # script to create or update the defined distros
  dbx-setup = pkgs.writeShellScriptBin "dbx-setup" ''
    echo "Constructing Distrobox containers from Nix definition..."
    ${pkgs.distrobox}/bin/distrobox-assemble create --file ${distroboxIni}
  '';

in
{

  environment.systemPackages = with pkgs; [
    # Container
    docker
    docker-compose
    lazydocker # makes docker less pain in the ass

    # Distro Box
    distrobox
    distroshelf # gui for distrobox
    dbx-setup # own script to create and update distros from templates

    # Virtual Machines
    qemu
    gnome-boxes

  ];

  ## Docker
  virtualisation.docker.enable = true;
  users.users.benjamin.extraGroups = lib.mkIf (lib.elem "benjamin" activeUsers) [
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
