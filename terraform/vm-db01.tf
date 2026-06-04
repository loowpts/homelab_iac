resource "proxmox_virtual_environment_vm" "db02" {
  node_name = "node"
  vm_id     = 203
  name      = "db01"
  tags      = ["terraform", "ubuntu"]

  scsi_hardware = "virtio-scsi-single"

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = false
  }

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = var.storage_name
    interface    = "scsi0"
    size         = 20
    discard      = "on"
    iothread     = true
  }

  vga {
    type = "std"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id      = var.storage_name
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id

    ip_config {
      ipv4 {
        address = "192.168.0.24/24"
        gateway = "192.168.0.1"
      }
    }

    dns {
      servers = ["8.8.8.8"]
    }
  }
}
