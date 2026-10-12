# Windows VFIO Session Design

Date: 2026-10-11

Status: Implemented in the repository. Built but not activated or live-tested.

## Goal

The repository defines a `windows-vm` command for Jezrien. After activation,
the command starts a Windows 11 virtual machine from a Linux TTY. The domain
receives the RX 9070 XT, both monitors, and selected USB devices.

The controller waits for Windows to stop and then attempts to return the GPU to
Linux. The normal boot configuration leaves the RX 9070 XT on its Linux
drivers. The design does not require the Quadro P600.

## Supported games

The first targets are WARDOGS and Escape from Tarkov. Both games use anti-cheat
software.

The generated domain exposes normal KVM/QEMU virtualization. It does not hide
the hypervisor or bypass anti-cheat checks. WARDOGS does not publish a
virtual-machine policy. Escape from Tarkov confirms that it uses BattlEye but
does not publish a clear virtual-machine policy.

Repository checks can inspect and build the domain. Only a live game launch
after activation can show whether each anti-cheat system accepts it.

Battlefield 6 is not a target. EA states that its anti-cheat detects virtual
machines and emulation. Star Citizen remains a Linux game for this use case.
Epic states that Easy Anti-Cheat does not support virtual machines.

Sources:

- [EA Battlefield 6 Secure Boot information](https://www.ea.com/games/battlefield/battlefield-6/news/secure-boot-information)
- [Epic Easy Anti-Cheat virtual-machine policy](https://www.epicgames.com/help/c-32735058/c-37477814/a21516107)
- [Escape from Tarkov anti-cheat information](https://www.escapefromtarkov.com/support/knowledge/446)
- [WARDOGS security and enforcement policy](https://www.wardogs.com/enforcement)

## Current hardware

Jezrien has the required isolation:

| Component | Address or identity | IOMMU group |
|---|---|---:|
| RX 9070 XT | `0000:2f:00.0`, `1002:7550` | 31 |
| RX 9070 XT display audio | `0000:2f:00.1`, `1002:ab40` | 32 |
| Optional USB controller | `0000:31:00.3`, `1022:149c` | 35 |

AMD-V, the AMD IOMMU, and interrupt remapping are active. The GPU provides a PCI bus reset method. The reset must still pass a live handoff test.

Jezrien has 62 GiB of memory and a Ryzen 9 5900X with 12 cores and 24 threads. The root filesystem has approximately 1.7 TiB free.

## User flow

After activation, use this exact sequence from a local TTY:

```text
niri-session
log out
windows-vm --check
windows-vm
shut down Windows
niri-session
```

`windows-vm --check` performs the unprivileged preflight. `windows-vm` asks
systemd to start one approved service through Polkit. The Polkit rule permits
only the configured user in an active local session to start
`windows-vm.service`.

For the first installation, replace `windows-vm` with:

```text
windows-vm-install <windows-iso>
```

The user supplies a readable official Windows 11 ISO. The install command
prepares the disk and installation media, then starts the same passthrough
service.

## Linux module structure

`modules/virtualization/vfio.nix` exports the opt-in dendritic NixOS module
`flake.modules.nixos.vfio`. All NixOS changes are behind `ryk.vfio.enable`.
The module owns:

- The libvirt and QEMU/KVM configuration.
- OVMF firmware with enrolled Secure Boot keys.
- A software TPM 2.0 device.
- The normal and installation domain definitions.
- `windows-vm.service`.
- The `windows-vm` and `windows-vm-install` commands.
- The narrow Polkit authorization for the primary user.
- The allowlisted USB attachment service and udev rules.

`modules/virtualization/_vfio/` contains the private support files. The
directory contains `windows_vm.py`, both domain templates, and their tests.
The leading underscore prevents `import-tree` from loading these files as
modules.

The implementation removed the unused `virtman.nix` module after moving its
required configuration into the VFIO module. Jezrien imports
`self.modules.nixos.vfio` and supplies its PCI addresses and USB identities.
Other hosts do not import this module.

## Virtual machine

The generated virtual machine uses these resources:

| Resource | Value |
|---|---|
| Firmware | UEFI through OVMF |
| Secure Boot | Enabled with enrolled default Microsoft certificates |
| TPM | Software TPM 2.0 |
| Machine type | Q35 |
| CPU mode | Host passthrough |
| Virtual CPUs | 16 threads |
| Memory | 32 GiB |
| System disk | 500 GiB thin-provisioned qcow2 |
| Disk interface | VirtIO SCSI with discard support |
| Network | QEMU user networking with a VirtIO adapter |
| Graphics | RX 9070 XT and its display-audio function |

The disk path is `/var/lib/libvirt/images/windows-vm.qcow2`. The file grows as
Windows writes data and has a maximum virtual size of 500 GiB. The domain keeps
its UEFI variables in `/var/lib/libvirt/qemu/nvram/windows-vm_VARS.fd`.

The implementation does not use huge pages or CPU pinning. Performance
measurements can justify these settings later.

## Windows installation

The repository does not download or store a Windows ISO. The user supplies an
official ISO to `windows-vm-install <windows-iso>`.

The install command:

1. Makes sure that the ISO exists and is readable.
2. Creates `/var/lib/libvirt/images/windows-vm.qcow2` if it does not exist.
3. Gives the new thin-provisioned qcow2 disk a 500 GiB virtual size.
4. Copies the ISO atomically to
   `/var/lib/libvirt/images/windows-vm-install.iso`.
5. Writes an installation marker and starts `windows-vm.service`.

The service defines the persistent libvirt domain from the installation
template. That template attaches the Windows ISO and the VirtIO driver ISO.
The controller removes the marker only after the domain starts.

The command preserves an existing virtual disk and UEFI variable store. After
Windows installation, `windows-vm` starts the normal domain without the
installation media.

## GPU handoff

The controller uses PCI addresses, not vendor and product IDs. Address-based
selection prevents accidental capture of another AMD device.

Before detachment, the controller makes sure that:

- No active or online graphical login session exists for the configured user.
- No listed graphical process remains.
- No process has a DRM node for the configured GPU open.
- The GPU uses `amdgpu`.
- The display-audio function uses `snd_hda_intel`.

If a preflight condition fails, the controller reports every diagnostic and
exits before it changes a driver. `windows-vm --check` calls this same
preflight without privileges.

The handoff sequence is:

1. Save the state of each bound virtual terminal console.
2. Unbind the virtual terminal consoles from the GPU.
3. Make sure that no process opened a GPU DRM node during the first steps.
4. Unbind display audio from `snd_hda_intel`.
5. Unbind graphics from `amdgpu`.
6. Bind both functions to `vfio-pci`.
7. Define and start the selected libvirt domain.
8. Wait until libvirt reports `shut off` or `crashed`.

The return sequence is:

1. Remove both GPU functions from `vfio-pci`.
2. Clear both driver overrides.
3. Reset the GPU through its PCI reset file.
4. Probe the GPU and audio functions with their Linux drivers.
5. Restore the saved virtual terminal console state.

The controller continues through every independent cleanup step and reports
combined restore errors. If service shutdown cannot stop an active domain, the
controller leaves both PCI functions on `vfio-pci` instead of racing QEMU for
the hardware.

If Linux cannot reclaim the GPU, the service reports the restore errors. The
supported recovery action is a normal reboot. Do not loop through unsafe reset
attempts.

## USB devices and KVM behavior

Jezrien passes these runtime USB identities:

| Device | USB identity |
|---|---|
| Xbox Wireless Adapter | `045e:02fe` |
| VIRPIL left stick | `3344:8384` |
| VIRPIL right stick | `3344:4384` |
| ZSA Moonlander | `3297:1969` |
| Razer Naga V2 Pro | `1532:00a8` |

The devices can remain behind their current hubs and KVM. The module does not
pass an entire USB controller. Each domain template marks all five devices as
optional, so a missing device does not prevent Windows from starting.

A udev rule reacts when a configured device appears. If the Windows domain is
running, the allowlisted helper inspects the live domain and attaches the
device once. This supports a keyboard or mouse that reconnects after the KVM
switches back from the MacBook. Linux keeps the device when the domain is
stopped.

Firmware flashing remains outside this design. The module recognizes only the
normal runtime identities above.

## Files and sharing

The host session uses the existing `dusty` account. The Windows guest does not
receive direct access to `/home/dusty`.

The implementation does not share a host directory. This boundary avoids
exposing browser data, source trees, SSH files, and agent credentials to
Windows.

## Failure handling

A failed preflight keeps the GPU on its Linux drivers.

If QEMU fails after GPU detachment, the service runs the return sequence. If a
USB device is absent, the optional domain entry does not block startup.

If a configured USB device reconnects through the KVM, the helper attaches it
only while the Windows domain runs. When libvirt reports that Windows stopped
or crashed, the service runs the return sequence.

A power loss cannot run cleanup. Linux binds the RX 9070 XT normally on the
next boot because the configuration does not bind it to VFIO during boot.

## Security boundary

The `dusty` user can start only `windows-vm.service` through the added Polkit
rule. The rule does not grant permission to manage arbitrary system services.

The udev helper accepts only the configured USB identities and the fixed
Windows domain name. The VM runs through the system libvirt instance. Windows
receives no host disk and no host home directory.

The implementation does not add hypervisor concealment, anti-cheat bypasses,
spoofed hardware identities, or similar measures.

## Verification

Repository verification does not activate the NixOS configuration.

The following checks completed before this documentation update:

- The controller unittest suite passed with 25 tests after its final Task 1
  fixes.
- The domain contract suite passed all five tests, including
  `virt-xml-validate` for both rendered XML files.
- `nix build .#checks.x86_64-linux.windows-vfio` completed successfully. This
  check compiles the controller and tests, runs the suites, validates the XML,
  and builds an enabled synthetic NixOS closure.
- `nix build .#nixosConfigurations.jezrien.config.system.build.toplevel`
  completed successfully.
- Evaluation returned Jezrien's exact VFIO values and all five USB identities.
- `./result/sw/bin/windows-vm --check` exited with status 1 while Niri was
  active. It reported the active Wayland session, Xwayland, and DRM owners. It
  did not request privileges or interrupt the display.

These checks prove that the repository builds the module and Jezrien closure.
They do not prove that Jezrien activated the module or handed the GPU to
Windows. `nix flake check` also remains unobserved in the recorded task
evidence.

Run these final commands after the documentation commit. This documentation
task did not run them:

```bash
nix flake check
nix build .#checks.x86_64-linux.windows-vfio
nix build .#nixosConfigurations.jezrien.config.system.build.toplevel
./result/sw/bin/windows-vm --check
```

Do not run an activation command as part of repository verification. After a
later activation, the live acceptance sequence is:

1. Start Niri and log out to a local TTY.
2. Run `windows-vm --check`.
3. Run `windows-vm-install <windows-iso>`.
4. Complete Windows installation on both monitors.
5. Shut down Windows and make sure that the Linux TTY returns.
6. Run `niri-session` and make sure that both monitors work.
7. Repeat the Windows-to-Linux cycle at least three times.
8. Switch the KVM to the MacBook and back while Windows runs.
9. Make sure that the ZSA and Razer devices return to Windows.
10. Launch WARDOGS and Escape from Tarkov without virtualization concealment.

Repeated live GPU handoff and game anti-cheat acceptance remain untested.

## Out of scope

The first implementation excludes:

- Battlefield 6 support.
- Anti-cheat concealment or bypasses.
- Firmware flashing through the VM.
- A second host GPU.
- Looking Glass.
- Host directory sharing.
- Huge pages and CPU pinning.
- Automatic Niri startup after Windows exits.
- Reboot-based VFIO binding.
