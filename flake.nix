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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      sops-nix,
      nvf,
      ...
    }@inputs:
    {
      nixosConfigurations = {

        #############  DESKTOP  #############
        rhodos = nixpkgs.lib.nixosSystem {
          specialArgs = rec {
            inherit inputs;
            username = "benjamin";
            dotfiles_path = "/home/${username}/code/dotfiles";
            sopsMod = ./modules/sops.nix;
          };
          modules = [
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            ./hosts/rhodos
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
            (
              { username, sopsMod, ... }:
              {
                home-manager.users.${username} = import ./users/${username}.nix;
                home-manager.extraSpecialArgs = { inherit inputs username sopsMod; };
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
              }
            )
          ];
        };

        #############  FRAMEWORK LAPTOP 13"  #############
        delos = nixpkgs.lib.nixosSystem {
          specialArgs = rec {
            inherit inputs;
            username = "benjamin";
            dotfiles_path = "/home/${username}/code/dotfiles";
            sopsMod = ./modules/sops.nix;
          };
          modules = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            ./hosts/delos
            # Collections
            ./collections/development.nix
            ./collections/office.nix
            ./collections/uni.nix
            ./collections/multimedia.nix
            ./collections/privacy.nix
            # Modules
            ./modules/common.nix
            ./modules/hyprland
            (
              { username, sopsMod, ... }:
              {
                home-manager.users.${username} = import ./users/${username}.nix;
                home-manager.extraSpecialArgs = { inherit inputs username sopsMod; };
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
              }
            )
          ];
        };

        #############  #############  #############
      };
    };
}
