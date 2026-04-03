{
  # Dosage: One 'nixos-rebuild switch' daily or as needed for restlessness.
  # Side effects: May include excessive reading of the Nixpkgs manual and
  # an irrational hatred of imperative file changes.
  description = "Therapeutic NixOS for a recovering distro hopper";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
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
          specialArgs = { inherit inputs; };
          modules = [
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            ./hosts/rhodos
            # Collections
            ./collections/development.nix
            ./collections/office.nix
            ./collections/uni.nix
            ./collections/gaming.nix
            # Modules
            ./modules/common.nix
            ./modules/winmgs/hyprland.nix
            ./modules/multimedia.nix
            ./modules/downloaders.nix
            {
              home-manager.users.benjamin = import ./home.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        #############  FRAMEWORK LAPTOP 13"  #############
        delos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            ./hosts/delos
            # Collections
            ./collections/development.nix
            ./collections/office.nix
            ./collections/uni.nix
            # Modules
            ./modules/common.nix
            ./modules/winmgs/hyprland.nix
            ./modules/multimedia.nix
            {
              home-manager.users.benjamin = import ./home.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        #############  #############  #############
      };
    };
}
