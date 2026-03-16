{ config, pkgs, lib, ... }:

{
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
    "virtio_scsi"
    "virtio_balloon"
  ];

  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  # Диск определяется nixos-generators (qcow format) при сборке образа.
  # При ручной установке раскомментировать:
  # fileSystems."/" = {
  #   device = "/dev/vda1";
  #   fsType = "ext4";
  # };

  # Сеть через networkd (совместимо с cloud-init)
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.enable = true;
  systemd.network.networks."10-eth" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
  };

  services.qemuGuest.enable = true;

  # cloud-init для первоначальной настройки (SSH keys, grow partition)
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  # Serial console для YC
  systemd.services."serial-getty@ttyS0".enable = true;
}
