{ config, pkgs, ... }:

{
  # System-wide dev tools
  environment.systemPackages = with pkgs; [

    # General
    git
    git-lfs
    fd
    fzf
    neovim
    ripgrep
    eza
    gnumake
    age
    mise
    just
    copyq

    # Terminal Emulators
    kitty

    # TUIs
    gh
    lazygit
    lazydocker
    opencode
    yazi
    timr-tui

    # Editors and Co
    vscode
    zed-editor
    obsidian
    qutebrowser

    # Container / Virt
    docker
    docker-compose

    # Languages
    rustup

    # Networking
    whosthere           # discover local devices
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
