# infra/proxmox

OpenTofu for the Proxmox **VMs** on roshar. LXCs keep using `pve-provision`,
which already owns template upload, CT creation, age-key injection and the
pool guardrail.

State lives in `terraform.tfstate` next to this file and is git-ignored: it
records vmids and volume ids, not secrets, but it is machine-local and should
not be a merge conflict. The API token is read from the environment, never from
a variable file.

## Prerequisites

The `omp@pve!agent` token needs two privileges beyond what it had for
containers — `VM.Config.HWType` (machine type `q35`, BIOS `ovmf`) and
`VM.Config.CDROM` (attaching the installer ISO). Everything else
(`VM.Allocate`, `VM.Config.{CPU,Memory,Disk,Network,Options}`, `VM.PowerMgmt`
on `/pool/agent-managed`, `Datastore.AllocateTemplate` on `/storage/local`,
`Datastore.AllocateSpace` on `/storage/local-lvm`, `SDN.Use` on `vmbr0`) is
already granted.

## Install nale

```sh
export PROXMOX_VE_API_TOKEN="$(cat ~/.config/pve/agent.token)"

iso=$(nix build --no-link --print-out-paths .#nale-installer-iso)/iso/nale-installer.iso

tofu init
tofu apply -var="installer_iso_path=$iso"        # creates the VM, boots the ISO
tofu output nale_ipv4                            # guest agent reports the address

# age identity into a tmpfs tree that nixos-anywhere copies onto the installed
# system, so sops-nix can decrypt on first boot
install -d -m 700 /dev/shm/nale-extra/var/lib/sops-nix
sops -d --input-type binary --output-type binary modules/hosts/nale/age-key.sops \
  > /dev/shm/nale-extra/var/lib/sops-nix/key.txt

# `nix develop` provides tofu, nixos-anywhere, sops and age
nixos-anywhere \
  --flake .#nale \
  --extra-files /dev/shm/nale-extra \
  --chown /var/lib/sops-nix 0:0 \
  root@<ip>

shred -u /dev/shm/nale-extra/var/lib/sops-nix/key.txt && rm -rf /dev/shm/nale-extra

# detach the installer and boot the installed system
tofu apply -var="installer_iso_path=$iso" -var="boot_from_disk=true"
```

From here comin owns the host: pushes to `master` land within a poll period,
and `testing-nale` is the per-host branch (comin runs those as `test`, so the
bootloader is untouched).

## Destroy

`tofu destroy` removes the VM and the uploaded ISO. It only ever touches
resources in `agent-managed`.
