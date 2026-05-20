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

    # Monitor Configurator for Hyprland
    monique.url = "github:ToRvaLDz/monique";

    # git-today
    git-today.url = "github:bitSheriff/git-today";

    # my own flakes
    my-flakes.url = "github:bitSheriff/my-flakes";
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
      ...
    }@inputs:
    {
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
            # Collections
            ./collections/development.nix
            ./collections/office.nix
            ./collections/uni.nix
            ./collections/gaming.nix
            ./collections/multimedia.nix
            ./collections/downloaders.nix
            ./collections/privacy.nix
            # Modules
            ./modules/common.nix
            ./modules/hyprland
            ./modules/meshtastic.nix
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
            # Collections
            ./collections/development.nix
            ./collections/office.nix
            ./collections/uni.nix
            ./collections/multimedia.nix
            ./collections/privacy.nix
            # Modules
            ./modules/common.nix
            ./modules/hyprland
            ./modules/meshtastic.nix
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
