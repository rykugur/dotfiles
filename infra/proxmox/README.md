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

## Install nale

Run from the dotfiles repo root:

```sh
nix develop --command just vm-install nale
```

The recipe builds the headless ISO, creates VM 120 in `agent-managed`, boots
the installer, reads its address through the guest agent, installs NixOS with
`nixos-anywhere`, and injects the sops-nix identity from tmpfs. It then ejects
the ISO, reboots from disk and verifies the btrfs root and active comin service.
It refuses to reinstall a VM already in OpenTofu state. Subsequent applies
with `installer_iso_path` set default to disk boot; only the initial install
passes `boot_from_disk=false`.

The host polls `comin-rollout-plan` for now, not `master`. Its per-host
`testing-nale` branch uses comin's `test` operation.

## Destroy

`tofu destroy` removes the VM and the uploaded ISO. It only ever touches
resources in `agent-managed`.
