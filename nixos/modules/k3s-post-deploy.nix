{ config, pkgs, lib, ... }:

let
  k8sManifestsDir = "/etc/yc-nixos/k8s";
in
{
  # Копируем k8s манифесты на хост
  environment.etc."yc-nixos/k8s/namespaces.yaml".source = ../../k8s/namespaces.yaml;
  environment.etc."yc-nixos/k8s/xray/xray-deployment.yaml".source = ../../k8s/xray/xray-deployment.yaml;
  environment.etc."yc-nixos/k8s/xray/xray-configmap.yaml".source = ../../k8s/xray/xray-configmap.yaml;
  environment.etc."yc-nixos/k8s/xray/xray-service.yaml".source = ../../k8s/xray/xray-service.yaml;
  environment.etc."yc-nixos/k8s/xray/xray-geodata-cronjob.yaml".source = ../../k8s/xray/xray-geodata-cronjob.yaml;
  environment.etc."yc-nixos/k8s/amneziawg/amneziawg-deployment.yaml".source = ../../k8s/amneziawg/amneziawg-deployment.yaml;
  environment.etc."yc-nixos/k8s/amneziawg/amneziawg-configmap.yaml".source = ../../k8s/amneziawg/amneziawg-configmap.yaml;
  environment.etc."yc-nixos/k8s/mtproto/mtg-deployment.yaml".source = ../../k8s/mtproto/mtg-deployment.yaml;

  systemd.services.k3s-post-deploy = {
    description = "Deploy k8s manifests after k3s is ready";
    after = [ "k3s.service" ];
    requires = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
    };

    path = with pkgs; [ kubectl coreutils gnugrep ];

    script = ''
      set -euo pipefail

      echo "Waiting for k3s to be ready..."
      for i in $(seq 1 60); do
        if kubectl get nodes 2>/dev/null | grep -q " Ready"; then
          echo "k3s node is Ready"
          break
        fi
        echo "Attempt $i/60: k3s not ready yet..."
        sleep 5
      done

      if ! kubectl get nodes | grep -q " Ready"; then
        echo "ERROR: k3s node not ready after 5 minutes"
        exit 1
      fi

      echo "Applying namespaces..."
      kubectl apply -f ${k8sManifestsDir}/namespaces.yaml

      echo "Waiting for namespaces..."
      sleep 2

      echo "Applying xray-core manifests..."
      kubectl apply -f ${k8sManifestsDir}/xray/

      echo "Applying AmneziaWG manifests..."
      kubectl apply -f ${k8sManifestsDir}/amneziawg/

      echo "Applying MTProto manifests..."
      kubectl apply -f ${k8sManifestsDir}/mtproto/

      echo "All k8s manifests applied successfully"
    '';
  };
}
