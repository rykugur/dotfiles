# Vasher + Hermes on one bare-metal NixOS machine — proposal

**Status:** Handoff for design and planning, not an approved implementation spec. No deployment or activation is authorized by this document.

## Intent and present constraints

Use one of the retired Proxmox machines as an always-on NixOS build/cache node and, if capacity and isolation permit, a Hermes host. The usable machine is an HP EliteDesk 800 G2 Mini 35 W with 16 GiB RAM, an i5 of unconfirmed model, a no-name 512 GB NVMe SSD, and a 250 GB Samsung 850 EVO SATA SSD. Dusty may replace the SATA SSD with a 1 TB TeamGroup Vulcan Z and is considering a known-brand NVMe replacement. The second machine is a Lenovo ThinkCentre M910q with 16 GiB RAM and a drive under RMA; defer k3s until it has healthy storage. Keep the playground separate from production. Preserve Vasher's existing tested-candidate and manual-promotion contract. Hermes runs only operator-defined jobs/tasks, with a private dashboard and the user's independently configured inference credentials.

Today Vasher is CT 300 on Roshar, defined in the dotfiles flake. Hermes is CT 200 there; its 4 GiB memory limit caused Roshar's kernel to OOM-kill `nix-daemon` during a build. Hermes is not deployed as a working service yet. At the last check, Vasher's Harmonia and monitor were active but the latest refresh service had exited 1; inspect a fresh candidate before migration. These observations are transient, not assumptions about future state.

## Proposed layout — now

- **Bare-metal NixOS host, `vasher`:** reuse the dotfiles flake's Vasher role and replace its LXC platform module with a hardware-specific bare-metal platform module (boot, filesystems, networking). Run the existing prebuild units, monitor, dashboard, and Harmonia on the host. Keep Nix's build concurrency bounded. Do not create a second independent Vasher codebase unless the existing role boundary proves inadequate.
- **Hermes placement, undecided:** compare a dedicated unprivileged service on the Vasher host with a separate NixOS VM. Remote inference may make a 4 GiB runtime envelope viable; the 4 GiB Hermes CT OOM during a Nix build does not establish the steady-state runtime requirement. Test evaluation, installation/update, interactive inference, and concurrent Vasher builds before choosing a limit. Keep the dashboard private on either placement and do not copy OMP's private token store.
- **Agent-to-builder boundary:** leave Vasher's deterministic monitor and build scripts in charge. Preserve the forced-command, validated JSON action channel even if Hermes runs on the same host; it may observe curated read-only status and request only the bounded verbs it is explicitly authorized to use. No root shell, arbitrary command generation, direct write to `master`, automatic candidate promotion, or access to cache/deploy/signing credentials. The current Hermes-based supervisor runs on Jezrien, which is not always on; move or reconfigure it deliberately only after the new placement and action channel work, so there is never an accidental second supervisor.

### Hermes placement tradeoffs

- **Unprivileged host service:** avoids a second operating system, guest memory reservation, and guest updates. It can share the host's package cache and capacity, which matters with 16 GiB RAM. It also shares the host kernel and Nix daemon: a compromised tool-enabled process or unbounded build has a shorter path to Vasher's credentials or build resources. Use a dedicated user, strict service sandbox, separate credentials, resource limits, and the bounded action channel; these reduce risk but are not VM isolation.
- **NixOS VM:** provides a separate kernel, Nix daemon, filesystem, identity, and credential boundary. It is preferable if Hermes receives broad tools or untrusted inputs. It adds guest lifecycle, disk, networking, update, and memory overhead on the same 16 GiB physical host. The VM does not protect against host compromise, disk failure, or power loss. Giving it 4 GiB is an experiment, not a proven minimum or maximum; Nix evaluation inside the guest can still exhaust that limit even if builds run elsewhere.

### Capacity and storage gate

The HP's 16 GiB is an observed capacity, not the proposed 32 GiB target. Start with bare-metal Vasher and measure real candidate-build memory, swap, thermals, and disk use. A 4 GiB Hermes host service may fit if remote inference and measured concurrent peaks leave headroom. A 4 GiB VM may also fit, but the guest's evaluation and updates need separate proof; do not reserve 8–12 GiB by default or require 32 GiB before a measured trial. Upgrade RAM or move Hermes to the Lenovo after its drive returns if either placement contends with Vasher. A 35 W mini and i5 of unknown model can throttle sustained builds; measure rather than assume throughput.

Inspect the no-name 512 GB NVMe's SMART health and kernel error history before trusting it for boot. The 1 TB TeamGroup SATA replacement would give `/nix/store` more headroom than the 250 GB 850 EVO, but install it only after checking its health. Choose boot, Nix store, and VM disk placement after identifying the actual drives and confirming health, not by brand alone. A clean SMART report cannot guarantee future reliability: keep the SOPS age identity and cache signing material independently recoverable, and retain CT 300 for rollback. Do not use the Lenovo's drive under RMA.

## Migration sequence

1. **Establish baseline:** get one clean Vasher candidate build on CT 300; inspect build status, cache serving, DNS, and the current signing public key. Fix the existing refresh error before introducing a migration variable. Record a rollback point; keep CT 300 intact during validation.
2. **Install NixOS on the healthy machine:** identify the HP's CPU and drives, check NVMe/SATA health, choose a disk layout, and add the bare-metal `vasher` platform to the existing dotfiles flake while retaining its role modules. Evaluate/build the target without activating an unverified configuration. Confirm networking and sufficient storage for `/nix/store`, persistent Vasher state, and Hermes only if its placement is approved.
3. **Migrate identities and state securely:** restore the existing SOPS age identity from the user's protected 1Password copy; carry over the existing cache-signing identity if retaining the same trusted public key, plus only the Git/deploy credentials and persistent build state actually needed. Never copy plaintext keys into Git or this proposal. Verify host-key changes through a trusted path, not by disabling SSH host-key checking. Plan the Vasher DNS/cache endpoint cutover so Jezrien can continue using its configured substituter and public key; keep old CT 300 available for rollback until the new cache is validated.
4. **Prove the host:** run a candidate build and verify its result, GC root, successful `cache-bump` publication, signed cache substitution from Jezrien, monitor/dashboard behavior, and explicit promotion still being manual. A failure must leave the last good candidate untouched. Only then retire the old Vasher CT and update runbooks/source-of-truth wiki.
5. **Deploy Hermes separately after choosing its boundary:** either install an unprivileged, sandboxed host service with separate credentials and resource limits or configure a NixOS VM with its own identity and disk. Port the CT's intended Hermes settings without assuming an LXC image fits either target. Confirm dashboard access, one interactive inference request, provider authentication, update-time memory use, and a concurrent Vasher build. Keep CT 200 until the new placement works, then retire it deliberately.
6. **Move supervision, then authorize tasks:** test read-only polling first, configure Hermes's identity for the existing bounded Vasher action channel, smoke-test an explicitly permitted verb, and only then move scheduled supervision from Jezrien. Start with one operator-defined task; verify its result and failure behavior before scheduling it. Avoid arbitrary agent-written shell commands on the builder.

## Later — only when the second machine returns

Build a separate playground k3s cluster from the two NixOS machines after the Lenovo M910q's drive replacement and health checks. Start with **one k3s server on the Lenovo and one agent on Vasher**; this is a two-node playground, **not an HA control plane**. Reserve/taint the Vasher agent node so Kubernetes experiments cannot displace host builds or Hermes; explicitly opt in workloads when capacity permits. Keep Vasher and Hermes managed by NixOS, not scheduled as k3s pods. Test how k3s resource demand interacts with the builder before admitting workloads. Do not install k3s now merely to anticipate the returned drive.

## Decisions for the receiving session

- Confirm the HP's exact i5 model, drive identity and SMART/kernel health, and disk layout before assigning a boot drive or moving the Nix store.
- Choose Hermes host service versus VM based on required tool isolation and measured memory under concurrent Vasher builds; 4 GiB remains a trial, not a proven requirement.
- Confirm which persistent Vasher paths/identities must migrate, what can be rebuilt, and the cache/DNS cutover and rollback sequence.
- Resolve the current CT 300 refresh failure before host migration. Keep all NixOS activations, Proxmox removals, DNS cutovers, and secret restoration as explicit operator steps.

This is a design proposal to review in OMP session `01a13744-7a3f-74d4-867c-41cb915e5015`, not permission to implement or switch hosts automatically.
