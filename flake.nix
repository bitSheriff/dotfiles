{
  description = "NixOS configuration with Noctalia and Home Manager";

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
        desktop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            ./hosts/desktop
            ./modules/common.nix
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.benjamin = import ./home.nix;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        #############  FRAMEWORK LAPTOP 13"  #############
        framework = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            home-manager.nixosModules.home-manager
            nvf.nixosModules.default
            ./hosts/framework
            ./modules/common.nix
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.benjamin = import ./home.nix;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        #############  #############  #############
      };
    };
}
