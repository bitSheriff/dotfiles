{ config, pkgs, ... }:

{
  # System-wide dev tools
  environment.systemPackages = with pkgs; [
    # General
    git
    fd
    fzf
    neovim
    ripgrep
    eza
    gnumake
    age
    qutebrowser

    # Terminal Emulators
    kitty

    # TUIs
    gh
    lazygit
    opencode

    vscode

    # Container / Virt
    docker
    docker-compose
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
