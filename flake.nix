{
  description = "NixOS configuration using flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = {self, 
             nixpkgs,
             ...}@inputs:
  let
    system = "aarch64-linux";
  in 
  {
    nixosConfigurations = {
      nixos = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system; };
        modules = [
          /home/nixos/keystone/flake.nix
        ];
      };
    };
  };
}
