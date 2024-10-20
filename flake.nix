{
  description = "NixOS configuration using flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    keystone-flake.url = "https://glpat-21FzbkxQfazustGFxTyX:x-oauth-basic@gitlab.com/labmap/keystone/-/archive/flake_dev/keystone-flake_dev.tar.gz";
#    keystone-flake.rev = "8e5bf06c48b85f89fb3e7fdaf918d0de4b313e66";  
  };  # Добавление flake из GitLab

  outputs = { self, nixpkgs, keystone-flake }@inputs: {
    # Please replace my-nixos with your hostname
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        # Import the previous configuration.nix we used,
        # so the old configuration file still takes effect
        ./configuration.nix
      ];
    };
  };
}

