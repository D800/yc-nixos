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

  outputs = { self, nixpkgs, agenix, nixos-generators, ... }:
  let
    # Целевая система — всегда x86_64-linux (Yandex Cloud VM)
    targetSystem = "x86_64-linux";

    # Системы, с которых можно собирать (включая кросс-компиляцию)
    buildSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

    nixosModules = [
      agenix.nixosModules.default
      ./nixos/configuration.nix
    ];
  in
  {
    nixosConfigurations.yc-nixos = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      modules = nixosModules;
    };

    # Образ доступен с любой хост-системы
    # На Darwin требуется linux-builder (nix.linux-builder или remote builder)
    # nix build .#image вызовет сборку x86_64-linux через remote builder
    packages = nixpkgs.lib.genAttrs buildSystems (_buildSystem: {
      image = nixos-generators.nixosGenerate {
        system = targetSystem;
        format = "qcow";
        modules = nixosModules;
      };
    });
  };
}
