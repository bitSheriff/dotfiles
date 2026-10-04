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
      additional_packages = "libxft2 libxrender1 libxtst6 libxi6 default-jdk eza zoxide";
      init = false;
      nvidia = true;
      pull = true;
      replace = true;
      # executed once after creation
      post_init_hooks = "";
      # executed everytime when distro is entered
      init_hooks = ''
        echo "Welcome to the MATLAB Distro Box"
      '';
    };
  };

  # generate the INI file
  distroboxIni = pkgs.writeText "distrobox.ini" (lib.generators.toINI { } distroboxSet);

  # script to create or update the defined distros
  dbx-setup = pkgs.writeShellScriptBin "dbx-setup" ''
    echo "Constructing Distrobox containers from Nix definition..."
    ${pkgs.distrobox}/bin/distrobox-assemble create --file ${distroboxIni}
  '';

  cfgDocker = config.cfg.development.virtualization.docker;
  cfgVm = config.cfg.development.virtualization.vm;
in
{

  environment.systemPackages =
    with pkgs;
    lib.optionals cfgDocker.enable [
      # Container
      docker
      docker-compose
      lazydocker # makes docker less pain in the ass

      # Distro Box
      distrobox
      distroshelf # gui for distrobox
      dbx-setup # own script to create and update distros from templates
    ]
    ++ lib.optionals cfgVm.enable [
      # Virtual Machines
      qemu
      gnome-boxes
    ];

  users.users.benjamin.extraGroups =
    lib.optionals (lib.elem "benjamin" activeUsers) (
      lib.optional cfgDocker.enable "docker" ++ lib.optional cfgVm.enable "libvirtd"
    );

  ## Docker
  virtualisation.docker.enable = lib.mkIf cfgDocker.enable true;

  # mainly used for distrobox
  virtualisation.podman = lib.mkIf cfgDocker.enable {
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
  environment.sessionVariables = lib.mkIf cfgDocker.enable {
    DISTROBOX_ENGINE = "podman";
  };

  ## Libvirt
  virtualisation.libvirtd = lib.mkIf cfgVm.enable {
    enable = true;
    # Enable TPM emulation (optional)
    qemu.swtpm.enable = true;
  };

  # Enable USB redirection (optional)
  virtualisation.spiceUSBRedirection.enable = lib.mkIf cfgVm.enable true;

}
