{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-yandex-cloud.nix
    ./modules/base.nix
    ./modules/firewall.nix
    ./modules/k3s.nix
    ./modules/k3s-post-deploy.nix
  ];

  system.stateVersion = "24.11";
}
