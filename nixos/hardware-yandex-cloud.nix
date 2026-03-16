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

  # Yandex Cloud VM disk
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
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
