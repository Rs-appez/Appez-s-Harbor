resource "proxmox_download_file" "alpine_cloud" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"

  url                = "https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/cloud/generic_alpine-3.24.1-x86_64-bios-cloudinit-r0.qcow2"
  checksum           = "6e2e6fe0572b6632527f268d3659e8fccebda4e1ee470fafe2c4d7b85b6a4df6"
  checksum_algorithm = "sha256"
  file_name          = "alpine-3.24.1.img"
  overwrite          = true
}

resource "proxmox_virtual_environment_vm" "alpine_template" {
  depends_on = [proxmox_download_file.alpine_cloud]

  name        = "alpine-base-template"
  description = "Alpine Linux with Cloud-Init and Qemu-Guest-Agent"
  node_name   = "pve"
  vm_id       = 9000
  template    = true

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    size         = 1
    file_id      = proxmox_download_file.alpine_cloud.id
  }

  cpu {
    cores = 1
    type  = "host"
  }

  agent {
    enabled = false
  }

  memory {
    dedicated = 512
  }

  network_device {
    bridge = "vmbr0"
  }

  # Cloud-init configuration
  initialization {
    datastore_id = "local-lvm"
    interface    = "scsi0"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  on_boot = false
}

resource "proxmox_virtual_environment_file" "alpine_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = <<-EOF
      #cloud-config
      runcmd:
        - echo "nameserver 1.1.1.1" > /etc/resolv.conf
        - apk update
        - apk add qemu-guest-agent
        - rc-update add qemu-guest-agent default
        - rc-service qemu-guest-agent start
    EOF

    file_name = "alpine-qemu-guest-agent.yaml"
  }
}
