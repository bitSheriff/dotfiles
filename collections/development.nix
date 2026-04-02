{ config, pkgs, ... }:

{
  imports = [
    ./../modules/neovim
    ./../modules/yazi
    ./../modules/zed
    ./../modules/notes.nix
    ./../modules/git.nix
    ./../modules/zellij.nix
  ];

  # System-wide dev tools
  environment.systemPackages = with pkgs; [

    # General
    git
    git-lfs # git large file storage
    fd # find rewritten in rust
    fzf
    ripgrep
    eza
    gnumake
    age # encryption
    mise # like nix but on project basis
    just # like makefile but better
    rsync
    bash # mainly for scripting
    croc # send files to another computer
    yq # yaml parser for the console
    jq # json parser for the console
    ouch # universal archiver (zip, rar, ...)

    # Terminal Emulators
    kitty

    # TUIs
    gh
    gh-dash # manage github issues in the terminal
    forgejo-cli # same for codeberg and forgejo
    lazygit # the best git tui
    lazydocker # makes docker less pain in the ass
    opencode
    gemini-cli

    timr-tui
    zellij # like tmux, but written in rust...
    delta # git viewer
    serie # git graph viewer in the terminal
    sshs # ssh viewer

    # Editors and Co
    zed-editor
    obsidian
    qutebrowser # browser with vim
    meld # diff viewer

    # Container / Virt
    docker
    docker-compose
    #distrobox
    #distroshelf
    gnome-boxes

    # Languages
    rustup
    glibc
    gcc
    clang
    deno
    python3
    uv # because python sucks without
    nixfmt # nix language formatter
    doxygen # create documentation
    hugo # blog engine

    # Networking
    whosthere # discover local devices
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
      shd101wyy.markdown-preview-enhanced
      myriad-dreamin.tinymist # Typst Language Server
      jnoortheen.nix-ide
      rust-lang.rust-analyzer
    ];
  };

  home-manager.users.benjamin = {

    # Mise
    programs.mise = {
      enable = true;
      enableZshIntegration = true;
      globalConfig.settings = {
        experimental = true;
        age.key_file = "~/.age/mise.key";
      };
      globalConfig.tools = {
        usage = "latest";
      };
    };

    # LazyGit
    programs.lazygit = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        customCommands = [
          {
            key = "<delete>";
            context = "files";
            command = "git update-index --assume-unchanged";
          }
          {
            key = "Q";
            context = "global";
            command = "exit";
          }
          {
            key = "M";
            context = "files";
            command = "git mergetool {{ .SelectedFile.Name }}";
            loadingText = "opening mergetool";
            output = "terminal";
          }
          {
            key = "O";
            context = "global";
            command = "nemo .";
          }
          {
            key = "<c-p>";
            context = "global";
            command = "git pushall";
          }
        ];
      };
    };

    # Television (fuzzy finder)
    programs.television = {
      enable = true;
      settings = {
        tick_rate = 50;
        default_channel = "files";
      };
      channels = {
        dotenv = {
          metadata = {
            name = "dotenv";
            description = "A channel to select from .env files";
            requirements = [ "fd" ];
          };
          source = {
            command = "fd -H --type f .env";
          };
        };
        audiovideo = {
          metadata = {
            name = "audio-video";
            description = "A channel to select from audio and video files";
            requirements = [ "fd" ];
          };
          source = {
            command = "fd --extension mp4 --extension mp3 --extension webm --extension mov --extension mkv --extension flac --extension m4a --extension m4v --extension m3u";
          };
        };
      };
    };
  };

}
