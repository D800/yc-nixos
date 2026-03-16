output "external_ip" {
  description = "External IP address of the VM"
  value       = yandex_compute_instance.nixos.network_interface[0].nat_ip_address
}

output "internal_ip" {
  description = "Internal IP address of the VM"
  value       = yandex_compute_instance.nixos.network_interface[0].ip_address
}

output "instance_id" {
  description = "Compute instance ID"
  value       = yandex_compute_instance.nixos.id
}
