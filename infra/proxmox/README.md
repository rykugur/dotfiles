# infra/proxmox

OpenTofu for the Proxmox **VMs** on roshar. LXCs keep using `pve-provision`,
which already owns template upload, CT creation, age-key injection and the
pool guardrail.

State and its backups live beside this file. They are ignored by Git but remain
plaintext on disk. Treat them as sensitive: they currently describe VM resources,
but future resources could record secrets. The install recipe uses `umask 077` so
new files are owner-only. Run `umask 077` before any manual `tofu` command, and
keep the state files and backups at mode 0600. The API token comes from the
environment, never a Terraform variable; do not put credentials in `.tfvars`
or a saved plan. Git ignores those files, but ignoring does not encrypt them.

## Prerequisites

The `omp@pve!agent` token needs two privileges beyond what it had for
containers — `VM.Config.HWType` (machine type `q35`, BIOS `ovmf`) and
`VM.Config.CDROM` (attaching the installer ISO). Everything else
(`VM.Allocate`, `VM.Config.{CPU,Memory,Disk,Network,Options}`, `VM.PowerMgmt`
on `/pool/agent-managed`, `Datastore.AllocateTemplate` on `/storage/local`,
`Datastore.AllocateSpace` on `/storage/local-lvm`, `SDN.Use` on `vmbr0`) is
already granted.

## Install a VM (elantris or rysn)

Run from the dotfiles repo root:

```sh
nix develop --command just vm-install elantris
nix develop --command just vm-install rysn
```

The recipe builds the headless ISO, creates the VM (`elantris_vm_id` = 121,
`rysn_vm_id` = 122, both in `agent-managed`), boots the installer, reads
its address through the guest agent, installs NixOS with `nixos-anywhere`,
and injects the sops-nix identity from tmpfs (skipped for hosts with no
`age-key.sops`, e.g. rysn). It then ejects the ISO, reboots from disk and
verifies the btrfs root and active comin service (or, for rysn, its
persistence mounts). It refuses to reinstall a VM already in OpenTofu
state. It is fully host-parameterized: variables follow
`<host>_installer_iso_path` / `<host>_boot_from_disk` / `<host>_vm_id`,
and `<host>_ipv4` / `<host>_vm_id` outputs drive the address wait and the
reboot call. Adding a new VM here only needs matching variables, a
resource, and those two outputs — the recipe itself needs no change.

elantris is attached only to VLAN 199 (`network_device.vlan_id`, see
`infra/unifi`) — no other guest is on that VLAN. Its installer ISO bakes
in a single dedicated admin SSH key
(`modules/hosts/elantris/_ssh-keys.nix`), never Dusty's personal keys.

## Destroy

`tofu destroy` removes a VM and its uploaded ISO. It only ever touches
resources in `agent-managed`.
