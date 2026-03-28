# Inside your flake.nix
outputs = { self, nixpkgs, ... }@inputs: {
  nixosConfigurations = {

    desktop = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./modules/common.nix
        ./hosts/desktop
      ];
    };
    
    framework = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./modules/common.nix
        ./hosts/framework
      ];
    };
  };
};
