{
  description = "NixOS configuration for Yandex Cloud VM with k3s (xray-core, AmneziaWG, MTProto)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, agenix, nixos-generators, ... }: {
    nixosConfigurations.yc-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        agenix.nixosModules.default
        ./nixos/configuration.nix
      ];
    };

    packages.x86_64-linux.image = nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      format = "qcow";
      modules = [
        agenix.nixosModules.default
        ./nixos/configuration.nix
      ];
    };
  };
}
