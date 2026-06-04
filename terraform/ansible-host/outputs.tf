output "vm_name" {
  description = "Name of the provisioned VM in Proxmox"
  value       = proxmox_vm_qemu.ansible_host.name
}

output "vm_id" {
  description = "Proxmox-assigned VM ID"
  value       = proxmox_vm_qemu.ansible_host.vmid
}

output "vm_ipv4" {
  description = "Primary IPv4 address reported by the QEMU guest agent (null until the agent reports in)"
  value       = proxmox_vm_qemu.ansible_host.default_ipv4_address
}
