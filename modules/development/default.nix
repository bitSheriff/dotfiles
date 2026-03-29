{ config, pkgs, ... }:

{
  imports = [
    ../notes.nix
  ];

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
    rsync
    bash                # mainly for scripting

    # Terminal Emulators
    kitty

    # TUIs
    gh
    gh-dash             # manage github issues in the terminal
    forgejo-cli         # same for codeberg and forgejo
    lazygit             # the best git tui
    lazydocker          # makes docker less pain in the ass
    opencode
    gemini-cli
    yazi                # terminal file explorer
    timr-tui
    zellij              # like tmux, but written in rust...

    # Editors and Co
    zed-editor
    obsidian
    qutebrowser

    # Container / Virt
    docker
    docker-compose
    distrobox
    distroshelf

    # Languages
    rustup
    glibc
    gcc
    clang
    deno
    python3
    nixfmt              # nix language formatter

    # Networking
    whosthere           # discover local devices
  ];

  # Enable Docker daemon
  virtualisation.docker.enable = true;
  # Add your user to the docker group automatically
  users.users.benjamin.extraGroups = [ "docker" ];
  virtualisation.podman = {
    enable = true;
  };

  # Specific Program Modules (enable deeper integration)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Critical for Nix-based development
    settings = {
      load_dotenv = true;

    };
  };

  # Visual Studio Code
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      vscodevim.vim
      yzhang.markdown-all-in-one
      myriad-dreamin.tinymist               # Typst Language Server
      jnoortheen.nix-ide
    ];
  };

}
