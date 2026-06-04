# --- Proxmox provider connection ---

variable "pm_api_url" {
  description = "Proxmox API endpoint, e.g. https://<pve-host>:8006/api2/json"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID (format: user@realm!tokenname)"
  type        = string
  sensitive   = true
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret (UUID)"
  type        = string
  sensitive   = true
}

# --- SSH connection used by the file provisioner to stage cloud-init snippets ---

variable "pve_user" {
  description = "SSH user on the Proxmox host (usually root)"
  type        = string
  default     = "root"
}

variable "pve_host" {
  description = "Proxmox host address used by the SSH provisioner"
  type        = string
}

variable "pve_node" {
  description = "Proxmox node name that will host the VM"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Local path to the private key used to SSH into the Proxmox host"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Local path to the public key injected into the VM via cloud-init"
  type        = string
}

# --- VM configuration ---

variable "vm_name" {
  description = "Name of the VM in Proxmox"
  type        = string
  default     = "docker-host"
}

variable "vm_template" {
  description = "Name of the Proxmox VM template to clone from"
  type        = string
}

variable "ci_user" {
  description = "Initial user created by cloud-init inside the VM"
  type        = string
  default     = "steven"
}

variable "vm_cores" {
  description = "vCPU cores allocated to the VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory in MiB allocated to the VM"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Root disk size (e.g. 80G)"
  type        = string
  default     = "80G"
}

variable "vm_storage" {
  description = "Proxmox storage pool for the VM's disks"
  type        = string
  default     = "local-lvm"
}

variable "vm_bridge" {
  description = "Proxmox network bridge attached to the VM"
  type        = string
  default     = "vmbr0"
}
