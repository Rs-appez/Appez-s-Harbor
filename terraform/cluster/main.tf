
resource "proxmox_virtual_environment_vm" "k3s_master" {
  name      = "k3s-master"
  node_name = "pve"

  clone {
    vm_id = 9000
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  initialization {
    user_data_file_id = "local:snippets/alpine-qemu-guest-agent.yaml"
    ip_config {
      ipv4 {
        address = var.master_ip
        gateway = var.gateway
      }
    }
    dns {
      servers = [var.dns_server, "1.1.1.1"]
    }
    user_account {
      username = "alpine"
      keys     = [var.ssh_public_key]
    }
  }
}

resource "proxmox_virtual_environment_vm" "k3s_workers" {
  count     = var.worker_count
  name      = "k3s-worker-${count.index}"
  node_name = "pve"

  clone {
    vm_id = 9000
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  initialization {
    user_data_file_id = "local:snippets/alpine-qemu-guest-agent.yaml"

    ip_config {
      ipv4 {
        address = "192.168.0.${var.worker_ip_start + count.index}/24"
        gateway = var.gateway
      }
    }
    dns {
      servers = [var.dns_server, "1.1.1.1"]
    }
    user_account {
      username = "alpine"
      keys     = [var.ssh_public_key]
    }
  }
}
