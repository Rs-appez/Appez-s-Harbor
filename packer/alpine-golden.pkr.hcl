locals {
  iso_url       = "https://dl-cdn.alpinelinux.org/alpine/v${var.alpine_version}/releases/x86_64/alpine-virt-${var.alpine_release}-x86_64.iso"
  iso_checksum  = "file:${local.iso_url}.sha256"
  template_name = "alpine-${var.alpine_version}-cloud"
}

source "proxmox-iso" "alpine" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_api_token
  insecure_skip_tls_verify = false
  node                     = var.proxmox_node

  vm_id                = var.template_vm_id
  vm_name              = local.template_name
  template_description = "Alpine ${var.alpine_release} golden image (cloud-init + qemu-guest-agent), built by Packer"
  tags                 = "alpine;golden;cloud-init"

  os              = "l26"
  machine         = "q35"
  bios            = "seabios" # OVMF would require an EFI vars disk; unnecessary here
  qemu_agent      = true      # REQUIRED: Packer learns the VM IP through the agent
  scsi_controller = "virtio-scsi-single"
  cores           = 2
  memory          = 1024

  disks {
    type         = "scsi"
    disk_size    = "2G" # intentionally small; growpart+resizefs expand on first boot of each clone
    storage_pool = var.vm_storage_pool
    format       = "raw"
    io_thread    = true
    discard      = true # TRIM passthrough for thin-provisioned storage
  }

  network_adapters {
    model  = "virtio"
    bridge = var.bridge
  }

  cloud_init              = true # cloud-init drive lives in the template, clones inherit it
  cloud_init_storage_pool = var.vm_storage_pool

  boot_iso {
    iso_url          = local.iso_url
    iso_checksum     = local.iso_checksum
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
  }

  # Served to the live ISO over HTTP by Packer itself
  http_content = {
    "/setup.sh"        = file("${path.root}/http/setup.sh")
    "/answers"         = file("${path.root}/http/answers")
    "/authorized_keys" = "${var.build_ssh_public_key}\n"
  }

  boot_wait = "20s"
  boot_command = [
    "root<enter><wait2>",
    "ifconfig eth0 up && udhcpc -i eth0 -q<enter><wait5>",
    "export BASE=http://{{ .HTTPIP }}:{{ .HTTPPort }}<enter>",
    "wget -qO /tmp/i.sh $BASE/setup.sh && sh /tmp/i.sh $BASE<enter>"
  ]
   # Key-only build access; the key is wiped again before templating
  ssh_username              = "root"
  ssh_private_key_file      = var.build_ssh_private_key_path
  ssh_clear_authorized_keys = true
  ssh_timeout               = "15m" # covers install + reboot into installed system
}

build {
  sources = ["source.proxmox-iso.alpine"]

  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    script           = "scripts/provision.sh"
    environment_vars = ["ALPINE_VERSION=${var.alpine_version}"]
  }
}
