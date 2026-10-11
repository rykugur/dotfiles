# Windows VFIO Session Design

Date: 2026-10-11

Status: Approved

## Goal

Add a `windows-vm` command for Jezrien. The command starts a Windows 11 virtual machine from a Linux TTY. The virtual machine receives the RX 9070 XT, both monitors, and selected USB devices.

When Windows shuts down, Linux takes the GPU back. The command returns to the TTY. The user can then run `niri-session` without a reboot.

The normal Linux session keeps the RX 9070 XT. The design does not require the Quadro P600.

## Supported games

The first targets are WARDOGS and Escape from Tarkov. Both games use anti-cheat software.

The virtual machine will expose normal KVM/QEMU virtualization. It will not hide the hypervisor or bypass anti-cheat checks. WARDOGS does not publish a virtual-machine policy. Escape from Tarkov confirms that it uses BattlEye but does not publish a clear virtual-machine policy.

The implementation can prove that the virtual machine starts. Only a live game launch can prove that each anti-cheat system accepts it.

Battlefield 6 is not a target. EA states that its anti-cheat detects virtual machines and emulation. Star Citizen remains a Linux game for this use case. Epic states that Easy Anti-Cheat does not support virtual machines.

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

The normal Linux flow is:

```text
TTY
  -> niri-session
  -> Linux owns the RX 9070 XT
  -> log out of Niri
  -> TTY
```

The Windows flow is:

```text
TTY
  -> windows-vm
  -> preflight checks
  -> Linux releases the RX 9070 XT
  -> Windows starts on both monitors
  -> Windows shuts down
  -> Linux takes the RX 9070 XT back
  -> TTY
```

The user runs both commands as `dusty`. The `windows-vm` command starts one approved system service through Polkit. It does not grant general root access.

A separate one-time install command accepts an official Windows 11 ISO. It creates the virtual disk and starts the same passthrough session with installation media attached.

## Linux module structure

Replace the unused legacy VFIO module with one opt-in dendritic NixOS module. `modules/virtualization/vfio.nix` will export `flake.modules.nixos.vfio`. The module owns the complete Windows session feature:

- The libvirt and QEMU configuration.
- OVMF firmware with Secure Boot.
- A software TPM 2.0 device.
- The virtual-machine definition.
- The system service for GPU handoff.
- The `windows-vm` and install commands.
- Polkit authorization for the primary user.
- USB attachment rules.

Runtime code, tests, and the domain template will live under `modules/virtualization/_vfio/`. The underscore keeps import-tree from loading those support files as modules.

Remove the unused `virtman.nix` module after its current QEMU, OVMF, and TPM configuration moves into the VFIO module. This prevents two libvirt configurations from diverging.

Jezrien will import `self.modules.nixos.vfio` and set host-specific PCI addresses and USB identities. Other hosts will not import it.

## Virtual machine

The virtual machine will use these resources:

| Resource | Value |
|---|---|
| Firmware | UEFI through OVMF |
| Secure Boot | Enabled |
| TPM | Software TPM 2.0 |
| Machine type | Q35 |
| CPU mode | Host passthrough |
| Virtual CPUs | 16 threads |
| Memory | 32 GiB |
| System disk | 500 GiB thin-provisioned qcow2 |
| Disk interface | VirtIO SCSI with discard support |
| Network | Libvirt NAT with a VirtIO adapter |
| Graphics | RX 9070 XT and its display-audio function |

The disk will live under `/var/lib/libvirt/images`. Thin provisioning means that the file grows as Windows writes data. The maximum virtual size is 500 GiB.

The virtual machine will keep persistent UEFI variables. Windows therefore keeps its Secure Boot and boot settings across sessions.

The design does not use huge pages or CPU pinning in the first implementation. These settings complicate host memory management and CPU topology. Performance measurements can justify them later.

## Windows installation

The repository will not download or store a Windows ISO. The user supplies an official ISO to the install command.

The install command will:

1. Make sure that the ISO exists and is readable.
2. Create the 500 GiB disk if it does not exist.
3. Define the persistent libvirt domain.
4. Attach the Windows ISO and the VirtIO driver ISO.
5. Start the normal GPU passthrough session.

The command is idempotent. It will not replace an existing virtual disk or UEFI variable store.

After Windows installation, the normal `windows-vm` command starts the installed system without installation media.

## GPU handoff

The system service will use PCI addresses, not vendor and product IDs. Address-based selection prevents accidental capture of another AMD device.

Before detachment, the service must make sure that:

- No graphical login session is active.
- Niri and Xwayland are not running.
- No process has the GPU DRM nodes open.
- The Windows domain is not already running.
- Both GPU PCI functions use their expected Linux drivers.

If a preflight condition fails, the service will stop before it changes a driver.

The handoff sequence is:

1. Save the state of each bound virtual terminal console.
2. Unbind the virtual terminal consoles from the GPU.
3. Unbind display audio from `snd_hda_intel`.
4. Unbind graphics from `amdgpu`.
5. Set `vfio-pci` as the driver override for both functions.
6. Bind both functions to `vfio-pci`.
7. Start the libvirt domain.
8. Wait until the domain stops.

The return sequence is:

1. Detach optional USB devices from the stopped domain.
2. Remove both GPU functions from `vfio-pci`.
3. Clear both driver overrides.
4. Reset the GPU through its supported PCI bus reset.
5. Probe the GPU and audio functions with their Linux drivers.
6. Restore the saved virtual terminal console state.
7. Make sure that the expected DRM nodes return.

The service will run cleanup after every failure that occurs after detachment. Cleanup operations will be idempotent, which means that they are safe to run more than once.

If Linux cannot reclaim the GPU, the service will print a clear error. The supported recovery action is a normal reboot. The service will not loop through unsafe reset attempts.

## USB devices and KVM behavior

The first implementation will pass these runtime USB identities:

| Device | USB identity |
|---|---|
| Xbox Wireless Adapter | `045e:02fe` |
| VIRPIL left stick | `3344:8384` |
| VIRPIL right stick | `3344:4384` |
| ZSA Moonlander | `3297:1969` |
| Razer Naga V2 Pro | `1532:00a8` |

The devices can remain behind their current hubs and KVM. The module will not pass an entire USB controller.

The domain definition will treat each USB device as optional. A missing device will not prevent Windows from starting.

A udev rule will react when a configured device appears. If the Windows domain is running, a narrow helper will attach that device to the domain. This handles a keyboard or mouse that reconnects after the KVM switches back from the MacBook.

The helper will be idempotent. It will not attach a device twice. When the domain is not running, Linux keeps the device.

Firmware flashing is outside this design. The module will recognize only the normal runtime identities above.

## Files and sharing

The host session uses the existing `dusty` account. The Windows guest does not receive direct access to `/home/dusty`.

The first implementation will not share a host directory. A later change can add one explicit shared directory after the VM path works. This avoids exposing browser data, source trees, SSH files, and agent credentials to Windows.

## Failure handling

The command must keep the GPU attached to Linux when a preflight check fails.

If QEMU fails to start after GPU detachment, the service must run the full return sequence.

If a USB device is absent, Windows must still start.

If a USB device reconnects through the KVM, the udev helper must attach it only when the Windows domain is running.

If Windows crashes, libvirt must report that the domain stopped. The system service must then run the normal return sequence.

A power loss cannot run cleanup. Linux must still bind the RX 9070 XT normally on the next boot because the configuration does not bind it to VFIO during boot.

## Security boundary

The `dusty` user can start and inspect only the Windows VM session service. Polkit will not grant permission to manage arbitrary system services.

The udev helper accepts only the configured USB identities and the fixed Windows domain name.

The VM runs through the system libvirt instance. Windows receives no host disk and no host home directory.

The implementation will not add hypervisor concealment, anti-cheat bypasses, spoofed hardware identities, or similar measures.

## Verification

Repository verification will not activate the NixOS configuration.

The implementation will run:

- `nix flake check`.
- A build of the Jezrien system closure or the smallest equivalent closure that contains the service and commands.
- Static checks for generated shell scripts.
- A safe `windows-vm --check` command that performs preflight checks without changing GPU ownership.

The real GPU handoff cannot run until the user activates the built configuration. After activation, the live acceptance sequence is:

1. Start Niri and then log out.
2. Run `windows-vm --check` from the TTY.
3. Run the install command with a Windows 11 ISO.
4. Complete Windows installation on both monitors.
5. Shut down Windows and make sure that the Linux TTY returns.
6. Run `niri-session` and make sure that both monitors work.
7. Repeat the Windows-to-Linux cycle at least three times.
8. Switch the KVM to the MacBook and back while Windows runs.
9. Make sure that the ZSA and Razer devices return to Windows.
10. Launch WARDOGS and Escape from Tarkov without virtualization concealment.

The feature is complete only after the repeated GPU handoff succeeds. Game acceptance remains controlled by each publisher.

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
