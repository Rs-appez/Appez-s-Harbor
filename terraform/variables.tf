variable "proxmox_api_endpoint" {
  type        = string
  description = "The Proxmox VE API URL"
}

variable "proxmox_api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the alpine user"
}

variable "gateway" {
  type    = string
  default = "192.168.0.1"
}

variable "master_ip" {
  type    = string
  default = "192.168.1.50/24"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "worker_ip_start" {
  type        = number
  default     = 51
  description = "The last octet of the IP address to start worker nodes at"
}
