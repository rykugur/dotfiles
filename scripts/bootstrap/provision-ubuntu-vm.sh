#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${CYAN}[create-vm]${NC} $*"; }
ok()  { echo -e "${GREEN}[create-vm]${NC} $*"; }

VMID="${VMID:-$(pvesh get /cluster/nextid)}"
NAME="${NAME:-ubuntu-noble}"
STORAGE="${STORAGE:-local-lvm}"
IMAGE="${IMAGE:-}"
CPU="${CPU:-2}"
RAM="${RAM:-2048}"
DISK="${DISK:-20}"

if [[ -z "${IMAGE}" ]]; then
  IMAGE="/tmp/noble-server-cloudimg-amd64.img"
  log "Downloading Ubuntu Noble cloud image..."
  wget -qO "${IMAGE}" https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
  ok "Image downloaded to ${IMAGE}"
else
  log "Using existing image: ${IMAGE}"
fi

log "Creating VM ${VMID} (${NAME}) — ${CPU} cores, ${RAM}MB RAM..."
qm create "${VMID}" --name "${NAME}" --cores "${CPU}" --memory "${RAM}" --net0 virtio,bridge=vmbr0 --serial0 socket --vga serial0 --agent enabled=1 --onboot 1
ok "VM created."

log "Importing disk from ${IMAGE} into ${STORAGE}..."
qm importdisk "${VMID}" "${IMAGE}" "${STORAGE}"
ok "Disk imported."

log "Configuring boot disk and cloud-init..."
qm set "${VMID}" --scsihw virtio-scsi-pci --scsi0 "${STORAGE}:vm-${VMID}-disk-0" --ide2 "${STORAGE}:cloudinit" --boot order=scsi0 --ciuser root
ok "Boot disk configured."

log "Resizing disk to ${DISK}G..."
qm resize "${VMID}" scsi0 "${DISK}G"
ok "Disk resized."

log "Starting VM..."
qm start "${VMID}"

ok "VM ${VMID} (${NAME}) created and started."
