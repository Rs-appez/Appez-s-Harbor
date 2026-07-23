variable "proxmox_url" {
  type        = string
  description = "The URL of the Proxmox API endpoint."
}

variable "proxmox_username" {
  type        = string
  description = "The Proxmox API token ID."
}

variable "proxmox_api_token" {
  type        = string
  description = "The Proxmox API token secret."
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "The Proxmox node name where the VM will be created."
  default     = "pve"
}

variable "iso_storage_pool" { default = "local" }
variable "vm_storage_pool" { default = "local-lvm" }
variable "bridge" { default = "vmbr0" }
variable "template_vm_id" { default = 9000 }
variable "alpine_version" { default = "3.20" }
variable "alpine_release" { default = "3.20.3" }
variable "build_ssh_public_key" { type = string } # ephemeral, generated per build
variable "build_ssh_private_key_path" { type = string }
