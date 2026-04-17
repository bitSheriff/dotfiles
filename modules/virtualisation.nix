{
  config,
  pkgs,
  username,
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
  ];

  # Enable Docker daemon
  virtualisation.docker.enable = true;

  # Add your user to the docker group automatically
  users.users.${username}.extraGroups = [ "docker" ];

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

}
