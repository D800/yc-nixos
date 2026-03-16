variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key" {
  description = "SSH public key for admin user"
  type        = string
}

variable "image_id" {
  description = "NixOS image ID (uploaded to YC)"
  type        = string
}
