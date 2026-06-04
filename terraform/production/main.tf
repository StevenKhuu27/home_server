terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret

  # Homelab Proxmox uses a self-signed certificate. Disabling verification is
  # acceptable here because the API endpoint is only reachable on the LAN.
  pm_tls_insecure = true
}

# Stage the cloud-init user-data snippet on the Proxmox host so that the VM
# can reference it via `cicustom` below. Proxmox reads snippets from
# /var/lib/vz/snippets on the node's "local" storage.
resource "null_resource" "cloud_init_config_files" {
  connection {
    type        = "ssh"
    user        = var.pve_user
    private_key = file(var.ssh_private_key_path)
    host        = var.pve_host
  }

  provisioner "file" {
    source      = "${path.module}/files/user_data.yml"
    destination = "/var/lib/vz/snippets/user_data_vm.yml"
  }
}

resource "proxmox_vm_qemu" "docker_host" {
  name        = var.vm_name
  target_node = var.pve_node
  clone       = var.vm_template
  depends_on  = [null_resource.cloud_init_config_files]

  cpu {
    cores = var.vm_cores
  }
  memory = var.vm_memory

  scsihw = "virtio-scsi-pci"
  boot   = "c"
  agent  = 1

  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.vm_disk_size
          storage = var.vm_storage
        }
      }
    }
    # Cloud-init drive replaces the deprecated `cloudinit_cdrom_storage`
    # argument from older versions of the Telmate provider.
    ide {
      ide2 {
        cloudinit {
          storage = var.vm_storage
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.vm_bridge
  }

  serial {
    id = 0
  }
  vga {
    type = "serial0"
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=dhcp"
  ciuser    = var.ci_user
  ciupgrade = false
  sshkeys   = file(var.ssh_public_key_path)
  cicustom  = "user=local:snippets/user_data_vm.yml"
}
