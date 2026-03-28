{ config, pkgs, ... }:

{
  # System-wide dev tools
  environment.systemPackages = with pkgs; [
    # General
    git
    gh
    fd
    fzf
    neovim
    ripgrep
    eza
    vim
    gnumake
    age
    qutebrowser

    # Terminal Emulators
    kitty

    vscode
    sublime4

    # Container / Virt
    docker
    docker-compose

    # AI Stuff
    opencode
  ];

  # Enable Docker daemon
  virtualisation.docker.enable = true;

  # Specific Program Modules (enable deeper integration)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Critical for Nix-based development
  };

  # Add your user to the docker group automatically
  users.users.benjamin.extraGroups = [ "docker" ];
}
