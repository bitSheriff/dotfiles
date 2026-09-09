{
  # Dosage: One 'nixos-rebuild switch' daily or as needed for restlessness.
  # Side effects: May include excessive reading of the Nixpkgs manual and
  # an irrational hatred of imperative file changes.
  description = "Therapeutic NixOS for a recovering distro-hopper";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix on the phone. Termux-the-terminal-emulator, none of Termux-the-distro.
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Monitor Configurator for Hyprland
    monique.url = "github:ToRvaLDz/monique";

    # git-today
    git-today.url = "github:bitSheriff/git-today";

    # my own flakes
    my-flakes.url = "github:bitSheriff/my-flakes";

    # treefmt-nix for formatting
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      sops-nix,
      nvf,
      disko,
      treefmt-nix,
      nix-on-droid,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.rustfmt.enable = true;
        }
      );
    in
    {
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);
      templates = import ./templates;

      #############  PIXEL PHONE (nix-on-droid)  #############
      # Build with `nix-on-droid switch --flake .#android` on the phone, or
      # `just android` from a machine that can reach it.
      nixOnDroidConfigurations.android = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          # nix-on-droid patches a handful of packages (proot, the bootstrap
          # tools) and expects its own overlay to be applied.
          overlays = [ nix-on-droid.overlays.default ];
        };
        modules = [ ./hosts/android ];
      };

      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      nixosConfigurations = {

        #############  DESKTOP  #############
        rhodos = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            activeUsers = [ "benjamin" ];
            dotfiles_path = "/home/benjamin/code/dotfiles";
          };
          modules = [
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            disko.nixosModules.disko
            ./hosts/rhodos
            # Overlays
            { nixpkgs.overlays = [ (import ./overlays inputs) ]; }
            # Feature flags (cfg.*)
            ./cfg.nix
            {
              cfg.notes.obsidian.enable = true;
              cfg.notes.supernote.enable = true;

              cfg.development.zed.enable = true;
              cfg.development.agentic.enable = true;
              cfg.development.agentic.pi-coding-agent.enable = true;
              cfg.development.agentic.claude-code.enable = true;

              cfg.browser.qutebrowser.enable = true;

              cfg.desktop.hyprland.enable = true;
              cfg.development.enable = true;
              cfg.development.languages.typst.enable = true;

              cfg.office.enable = true;
              cfg.office.libre-office.enable = true;
              cfg.office.marktext.enable = true;

              cfg.uni.enable = true;

              cfg.communication.signal.enable = true;
              cfg.communication.matrix.enable = true;
              cfg.socials.irc.enable = true;

              cfg.gaming.enable = true;
              cfg.gaming.steam.enable = true;
              cfg.gaming.heroic.enable = true;

              cfg.multimedia.enable = true;

              cfg.downloaders.enable = true;
              cfg.downloaders.qbittorrent.enable = true;
              cfg.downloaders.jdownloader.enable = true;

              cfg.privacy.enable = true;
              cfg.multimedia.eilmeldung.enable = true;
            }
            (
              {
                activeUsers,
                inputs,
                ...
              }:
              {
                imports = [
                  (nixpkgs.lib.optionalAttrs (nixpkgs.lib.elem "benjamin" activeUsers) (import ./users/benjamin.nix))
                  (nixpkgs.lib.optionalAttrs (nixpkgs.lib.elem "guest" activeUsers) (import ./users/guest.nix))
                ];
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.extraSpecialArgs = { inherit inputs activeUsers; };
              }
            )
          ];
        };

        #############  FRAMEWORK LAPTOP 13"  #############
        delos = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            activeUsers = [ "benjamin" ];
            dotfiles_path = "/home/benjamin/code/dotfiles";
          };
          modules = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            disko.nixosModules.disko
            ./hosts/delos
            # Overlays
            { nixpkgs.overlays = [ (import ./overlays inputs) ]; }
            # Feature flags (cfg.*)
            ./cfg.nix
            {
              cfg.notes.obsidian.enable = true;
              cfg.notes.supernote.enable = true;
              cfg.development.zed.enable = true;
              cfg.development.agentic.enable = true;
              cfg.development.agentic.pi-coding-agent.enable = true;
              cfg.development.agentic.claude-code.enable = true;
              cfg.development.languages.typst.enable = true;
              cfg.browser.qutebrowser.enable = true;
              cfg.desktop.hyprland.enable = true;
              cfg.development.enable = true;
              cfg.office.enable = true;
              cfg.office.libre-office.enable = true;
              cfg.office.marktext.enable = true;
              cfg.uni.enable = true;
              cfg.multimedia.enable = true;
              cfg.privacy.enable = true;
              cfg.multimedia.eilmeldung.enable = true;

              cfg.communication.signal.enable = true;
              cfg.communication.matrix.enable = true;
              cfg.socials.irc.enable = true;
            }
            (
              {
                activeUsers,
                inputs,
                ...
              }:
              {
                imports = [
                  (nixpkgs.lib.optionalAttrs (nixpkgs.lib.elem "benjamin" activeUsers) (import ./users/benjamin.nix))
                  (nixpkgs.lib.optionalAttrs (nixpkgs.lib.elem "guest" activeUsers) (import ./users/guest.nix))
                ];
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.extraSpecialArgs = { inherit inputs activeUsers; };
              }
            )
          ];
        };

        #############  #############  #############
      };
    };
}
