resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "node"

  source_raw {
    data = <<-EOF
      #cloud-config
      ssh_pwauth: true
      users:
        - name: deploy
          groups: [sudo, adm]
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          lock_passwd: false
          ssh_authorized_keys:
            - ${var.vm_ssh_public_key}
      chpasswd:
        expire: false
        list: |
          deploy:${var.vm_password}
    EOF
    file_name = "ubuntu2404-cloud-init.yaml"
  }
}
