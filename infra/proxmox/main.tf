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
    path      = var.installer_iso_path
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
    file_id = proxmox_virtual_environment_file.nale_installer.id
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  agent {
    enabled = true
  }

  # Installer first; flip to disk-only once nixos-anywhere has run (see
  # README.md), which also proves the system boots on its own bootloader.
  boot_order = var.boot_from_disk ? ["scsi0"] : ["ide3", "scsi0"]

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
