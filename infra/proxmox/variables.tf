variable "pve_endpoint" {
  type    = string
  default = "https://roshar.local.ryk.sh:8006/"
}

variable "node_name" {
  type    = string
  default = "roshar"
}

variable "pool_id" {
  description = "Only this pool is agent-writable; pve-provision enforces the same boundary."
  type        = string
  default     = "agent-managed"
}

variable "disk_datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "nale_vm_id" {
  type    = number
  default = 120
}

variable "nale_installer_iso_path" {
  description = "Result of `nix build .#nale-installer-iso` (…/iso/nale-installer.iso)."
  type        = string
}

variable "nale_boot_from_disk" {
  description = "Boot the installed system by default; set false only during initial installation."
  type        = bool
  default     = true
}

variable "elantris_vm_id" {
  type    = number
  default = 121
}

variable "elantris_vlan_id" {
  description = "World VLAN, see infra/unifi. Tagged on vmbr0; untagged (no vlan_id) is the default/native VLAN nale uses."
  type        = number
  default     = 199
}

variable "elantris_installer_iso_path" {
  description = "Result of `nix build .#elantris-installer-iso` (…/iso/elantris-installer.iso)."
  type        = string
}

variable "elantris_boot_from_disk" {
  description = "Boot the installed system by default; set false only during initial installation."
  type        = bool
  default     = true
}
