{
  description = "NixOS configuration using flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    keystone-flake.url = "https://glpat-21FzbkxQfazustGFxTyX:x-oauth-basic@gitlab.com/labmap/keystone/";
    keystone-flake.rev = "8e5bf06c48b85f89fb3e7fdaf918d0de4b313e66";  
  };

	outputs = { self, nixpkgs, keystone-flake, ... }: {
		nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
			system = "aarch64-linux";
			modules = [
				./hardware-configuration.nix
				keystone-flake.nixosModules.keystoneModule
			];
			config = {
				keystone.enable = true;  
			};
		};
	};
}

