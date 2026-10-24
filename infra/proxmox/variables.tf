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

variable "elantris_vm_id" {
  type    = number
  default = 121
}

variable "elantris_vlan_id" {
  description = "World VLAN, see infra/unifi. Tagged on vmbr0; untagged (no vlan_id) is the default/native VLAN other guests use."
  type        = number
  default     = 199
}

variable "elantris_installer_iso_path" {
  description = "Result of `nix build .#elantris-installer-iso` (…/iso/elantris-installer.iso). Defaults to the path already in state so installing a different host doesn't require this unrelated value — a real reinstall still overrides it explicitly."
  type        = string
  default     = "/nix/store/lrjpcqirk54msl89acsl2ijbmlwi4j16-elantris-installer.iso/iso/elantris-installer.iso"
}

variable "elantris_boot_from_disk" {
  description = "Boot the installed system by default; set false only during initial installation."
  type        = bool
  default     = true
}

variable "rysn_vm_id" {
  type    = number
  default = 122
}

variable "rysn_installer_iso_path" {
  description = "Result of `nix build .#rysn-installer-iso` (…/iso/rysn-installer.iso). Defaults to the path already in state so installing a different host doesn't require this unrelated value — a real reinstall still overrides it explicitly."
  type        = string
  default     = "/nix/store/wk75wcy8hzpfdq8jxgvf5l427sxvr57f-rysn-installer.iso/iso/rysn-installer.iso"
}

variable "rysn_boot_from_disk" {
  description = "Boot the installed system by default; set false only during initial installation."
  type        = bool
  default     = true
}
