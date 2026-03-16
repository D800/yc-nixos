{ config, pkgs, lib, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = builtins.toString [
      "--disable=servicelb"
      "--disable=traefik"  # Установим Traefik через HelmChartConfig с кастомными портами
      "--write-kubeconfig-mode=644"
      # --tls-san добавится после получения IP
    ];
  };

  # k3s требует контейнерный рантайм
  virtualisation.containerd.enable = true;

  # Traefik через встроенный HelmChart k3s (с кастомной конфигурацией)
  environment.etc."rancher/k3s/server/manifests/traefik.yaml".source =
    ../../k8s/traefik/HelmChartConfig.yaml;

  systemd.services.k3s = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
