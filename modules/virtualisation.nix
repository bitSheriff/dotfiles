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
  virtualisation.podman = {
    enable = true;
  };

}
