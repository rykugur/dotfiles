terraform {
  required_version = ">= 1.8"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.117"
    }
  }
}

# Authentication comes from the environment, so no credential ever lands in
# this repo or in state:
#   export PROXMOX_VE_API_TOKEN="$(cat ~/.config/pve/agent.token)"
# The token is `omp@pve!agent`, scoped to pool `agent-managed`.
provider "proxmox" {
  endpoint = var.pve_endpoint
  insecure = true # roshar serves its own CA-signed cert
}

# Headless NixOS installer: built by `nix build .#nale-installer-iso`, which
# bakes Dusty's SSH keys and the guest agent in, so nixos-anywhere can reach
# the booted installer without touching the Proxmox console.
resource "proxmox_virtual_environment_file" "nale_installer" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name

  source_file {
    path      = var.nale_installer_iso_path
    file_name = "nale-installer.iso"
  }
}

resource "proxmox_virtual_environment_vm" "nale" {
  name      = "nale"
  node_name = var.node_name
  vm_id     = var.nale_vm_id
  pool_id   = var.pool_id

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  # OVMF needs its own small volume for EFI variables.
  efi_disk {
    datastore_id = var.disk_datastore_id
    type         = "4m"
    file_format  = "raw"
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.disk_datastore_id
    interface    = "scsi0"
    size         = 64
    discard      = "on"
    ssd          = true
    file_format  = "raw"
  }

  cdrom {
    # The provider ignores the deprecated `enabled` flag; use `none` to
    # actually eject the installer once disko has installed the system.
    file_id = var.nale_boot_from_disk ? "none" : proxmox_virtual_environment_file.nale_installer.id
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  agent {
    enabled = true
  }

  # PVE retains the empty IDE drive in the boot-order list after ejecting its
  # ISO. Boot the installed disk first; the empty IDE drive cannot boot.
  boot_order = var.nale_boot_from_disk ? ["scsi0", "ide3"] : ["ide3", "scsi0"]

  operating_system {
    type = "l26"
  }

  on_boot         = true
  stop_on_destroy = true

  lifecycle {
    # disko owns the disk contents; Terraform must never re-create the volume
    # after the OS is installed.
    ignore_changes = [disk[0].size]
  }
}

output "nale_ipv4" {
  description = "Addresses reported by the guest agent (installer or installed system)."
  value       = proxmox_virtual_environment_vm.nale.ipv4_addresses
}

output "nale_vm_id" {
  value = var.nale_vm_id
}

# Headless NixOS installer for elantris: built by
# `nix build .#elantris-installer-iso`, which bakes the dedicated
# elantris-admin key in (not Dusty's personal/jezrien/taln keys), so
# nixos-anywhere can reach the booted installer without touching the
# Proxmox console.
resource "proxmox_virtual_environment_file" "elantris_installer" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name

  source_file {
    path      = var.elantris_installer_iso_path
    file_name = "elantris-installer.iso"
  }
}

# Isolated OpenRig agent world VM. Attached only to VLAN 199 ("World", see
# infra/unifi) — no other guest is on this VLAN, and its firewall policies
# are the actual security boundary, not anything inside this resource.
resource "proxmox_virtual_environment_vm" "elantris" {
  name      = "elantris"
  node_name = var.node_name
  vm_id     = var.elantris_vm_id
  pool_id   = var.pool_id

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  # OVMF needs its own small volume for EFI variables.
  efi_disk {
    datastore_id = var.disk_datastore_id
    type         = "4m"
    file_format  = "raw"
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.disk_datastore_id
    interface    = "scsi0"
    size         = 64
    discard      = "on"
    ssd          = true
    file_format  = "raw"
  }

  cdrom {
    # The provider ignores the deprecated `enabled` flag; use `none` to
    # actually eject the installer once disko has installed the system.
    file_id = var.elantris_boot_from_disk ? "none" : proxmox_virtual_environment_file.elantris_installer.id
  }

  network_device {
    bridge  = "vmbr0"
    model   = "virtio"
    vlan_id = var.elantris_vlan_id
  }

  agent {
    enabled = true
  }

  # PVE retains the empty IDE drive in the boot-order list after ejecting its
  # ISO. Boot the installed disk first; the empty IDE drive cannot boot.
  boot_order = var.elantris_boot_from_disk ? ["scsi0", "ide3"] : ["ide3", "scsi0"]

  operating_system {
    type = "l26"
  }

  on_boot         = true
  stop_on_destroy = true

  lifecycle {
    # disko owns the disk contents; Terraform must never re-create the volume
    # after the OS is installed.
    ignore_changes = [disk[0].size]
  }
}

output "elantris_ipv4" {
  description = "Addresses reported by the guest agent (installer or installed system)."
  value       = proxmox_virtual_environment_vm.elantris.ipv4_addresses
}

output "elantris_vm_id" {
  value = var.elantris_vm_id
}
