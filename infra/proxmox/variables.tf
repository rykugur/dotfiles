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

variable "installer_iso_path" {
  description = "Result of `nix build .#nale-installer-iso` (…/iso/nale-installer.iso)."
  type        = string
}

variable "boot_from_disk" {
  description = "false while installing from the ISO, true once NixOS is on scsi0."
  type        = bool
  default     = false
}
