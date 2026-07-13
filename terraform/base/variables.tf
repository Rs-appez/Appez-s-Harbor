variable "proxmox_api_endpoint" {
  type        = string
  description = "The Proxmox VE API URL"
}

variable "proxmox_api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key for Proxmox"
  default     = "~/.ssh/proxmox"
}
