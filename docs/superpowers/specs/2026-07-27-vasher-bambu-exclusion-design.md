# Vasher Bambu Studio Exclusion Design

**Date:** 2026-07-27  
**Status:** Approved design; awaiting written-spec review

## Problem

Vasher's nightly candidate build reached `bambu-studio-02.08.00.50.drv`, consumed all 12 GiB RAM and 2 GiB swap, and left the LXC alive but unresponsive. The candidate unit did not return a Nix failure before the operator killed it from the Proxmox UI. The existing `max-jobs = 1` constraint serialized derivations but cannot bound a single Bambu Studio build.

## Decision

Vasher will prebuild a dedicated `jezrien-prebuild` NixOS configuration that is identical to the real `jezrien` configuration except that Home Manager omits `bambu-studio`.

The real `nixosConfigurations.jezrien` remains unchanged. It continues to include Bambu Studio and remains the only configuration switched on Jezrien.

## Architecture

### Optional Bambu package

The Home Manager 3D-printing group gains a narrowly scoped `ryk.printing3d.enableBambuStudio` option, defaulting to `true`. The group always retains FreeCAD, Orca Slicer, and Qidi Slicer. It includes Bambu Studio only when the option is enabled.

### Shared Jezrien configuration constructor

The Jezrien host module factors the existing `nixosSystem` definition into one shared constructor. It exposes:

- `nixosConfigurations.jezrien`: invokes the constructor without overrides; Bambu remains enabled.
- `nixosConfigurations.jezrien-prebuild`: invokes the same constructor with a final Home Manager override setting `ryk.printing3d.enableBambuStudio = false`.

No module list is duplicated. The two targets share all unaffected package derivations and their store hashes.

### Vasher target and status

Vasher's prebuilder targets `nixosConfigurations.jezrien-prebuild.config.system.build.toplevel` instead of the real Jezrien top-level target. Its successful and failed status JSON includes:

```json
"excludedPackages": ["bambu-studio"]
```

This makes the partial-closure contract visible to operators. The candidate may publish `cache-bump` after successfully building the reduced target, because it verifies the updated lockfile and every prebuilt path except the declared exclusion.

## Promotion behavior

Promotion remains unchanged:

1. Jezrien fast-forwards `master` to `cache-bump`.
2. Jezrien switches the real `nixosConfigurations.jezrien` target.
3. Nix substitutes all matching signed paths from Vasher.
4. Bambu Studio has no Vasher narinfo, so Nix builds it locally as a normal cache miss.

The aggregate Home Manager and top-level outputs may differ between the reduced and real configurations. This is expected and cheap. The Bambu derivation is the only deliberate heavyweight local miss.

## Safety and operation

- Keep Vasher's prebuild units runtime-masked until this target is deployed.
- Do not change the nightly timer, manual promotion flow, cache signing, retention, SSH policy, CT memory, or Nix concurrency settings.
- If another heavyweight derivation later wedges Vasher, add it only through the same explicit option and `excludedPackages` status contract; do not silently weaken prebuild coverage.

## Verification

- Evaluate the real Jezrien configuration and confirm Bambu Studio remains present.
- Evaluate the prebuild configuration and confirm Bambu Studio is absent while FreeCAD, Orca Slicer, and Qidi Slicer remain present.
- Build the reduced prebuild target without starting Vasher services.
- Deploy the new Vasher target, unmask its services/timers, then run one detached candidate build.
- Confirm `last-build.json` reports success, `excludedPackages` contains only `bambu-studio`, and `cache-bump` advances.
- Promote the candidate on Jezrien; verify Nix substitutes the shared closure and builds Bambu locally.
