# Vasher Bambu Studio Exclusion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep Bambu Studio in Jezrien's real configuration while preventing Vasher from prebuilding that memory-intensive derivation.

**Architecture:** Add a default-enabled Home Manager option controlling only Bambu Studio, then expose a second Jezrien configuration from the existing shared `nixosSystem` module list with that option disabled. Vasher builds the reduced target and records its declared exclusion in `last-build.json`; promotion still switches the unchanged full Jezrien target.

**Tech Stack:** Nix flakes, NixOS modules, Home Manager, Bash, jq.

## Global Constraints

- Real `nixosConfigurations.jezrien` must still include Bambu Studio and remain the only Jezrien switch target.
- `nixosConfigurations.jezrien-prebuild` must share Jezrien's module list and differ only by `ryk.printing3d.enableBambuStudio = false`.
- The 3D-printing group must still install `freecad-wayland`, `orca-slicer`, and `qidi-slicer-bin` in both targets.
- Vasher must build `nixosConfigurations.jezrien-prebuild.config.system.build.toplevel`.
- Every success and failure `last-build.json` record must include `excludedPackages: ["bambu-studio"]`.
- Do not change timers, Git promotion, cache signing, retention, SSH policy, CT memory, or Nix concurrency.
- Keep Vasher prebuild services runtime-masked until the new Vasher system is deployed.

---

### Task 1: Model and evaluate the Bambu-excluded configuration

**Files:**
- Modify: `modules/groups/printing3d.nix:1-15`
- Modify: `modules/hosts/jezrien/default.nix:8-206`
- Create: `scripts/tests/test-vasher-bambu-exclusion.sh`

**Interfaces:**
- Produces the Home Manager boolean option `ryk.printing3d.enableBambuStudio`, whose default is `true`.
- Produces `nixosConfigurations.jezrien-prebuild`, where `config.home-manager.users.dusty.ryk.printing3d.enableBambuStudio` is `false`.
- Consumes the existing `hmModules`, `username`, `inputs`, and `self` bindings in `modules/hosts/jezrien/default.nix`.

- [ ] **Step 1: Write the failing configuration regression test**

Create `scripts/tests/test-vasher-bambu-exclusion.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
packages_attr='config.home-manager.users.dusty.home.packages'

package_names() {
  nix eval "$repo_root#nixosConfigurations.$1.$packages_attr" \
    --apply 'builtins.map (package: package.name)' --json
}

real_enabled=$(nix eval "$repo_root#nixosConfigurations.jezrien.config.home-manager.users.dusty.ryk.printing3d.enableBambuStudio" --raw)
prebuild_enabled=$(nix eval "$repo_root#nixosConfigurations.jezrien-prebuild.config.home-manager.users.dusty.ryk.printing3d.enableBambuStudio" --raw)

test "$real_enabled" = true
test "$prebuild_enabled" = false

real_packages=$(package_names jezrien)
prebuild_packages=$(package_names jezrien-prebuild)

jq -e 'any(startswith("bambu-studio"))' <<<"$real_packages" >/dev/null
! jq -e 'any(startswith("bambu-studio"))' <<<"$prebuild_packages" >/dev/null

for package in freecad-wayland orca-slicer qidi-slicer-bin; do
  jq -e --arg package "$package" 'any(startswith($package))' <<<"$real_packages" >/dev/null
  jq -e --arg package "$package" 'any(startswith($package))' <<<"$prebuild_packages" >/dev/null
done

nix eval "$repo_root#nixosConfigurations.jezrien-prebuild.config.system.build.toplevel.drvPath" --raw >/dev/null
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash scripts/tests/test-vasher-bambu-exclusion.sh
```

Expected: nonzero exit because `nixosConfigurations.jezrien-prebuild` does not yet exist.

- [ ] **Step 3: Add the default-enabled Bambu option**

Replace `modules/groups/printing3d.nix` with:

```nix
{ ... }:
{
  flake.modules.homeManager._3dp =
    { config, lib, pkgs, ... }:
    {
      options.ryk.printing3d.enableBambuStudio = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install Bambu Studio.";
      };

      config.home.packages = with pkgs;
        [
          freecad-wayland
          orca-slicer
          qidi-slicer-bin
        ]
        ++ lib.optionals config.ryk.printing3d.enableBambuStudio [ bambu-studio ];
    };
}
```

- [ ] **Step 4: Factor Jezrien's existing configuration without duplicating modules**

In `modules/hosts/jezrien/default.nix`, add this local binding immediately after `hmModules`:

```nix
mkJezrien = extraModules:
  inputs.nixpkgs.lib.nixosSystem {
    modules = [
      # Move the existing `modules` list from the current Jezrien declaration here,
      # unchanged: it starts with `../../../legacy-modules/desktop`, ends with the
      # existing `home-manager` module, and includes every item currently at lines
      # 16-194 in the same order.
    ] ++ extraModules;
    specialArgs = {
      inherit inputs username;
      outputs = inputs.self;
      hostname = "jezrien";
    };
  };
```

Then replace the current single `flake.nixosConfigurations.jezrien = ...` assignment with:

```nix
flake.nixosConfigurations = {
  jezrien = mkJezrien [ ];
  jezrien-prebuild = mkJezrien [
    {
      home-manager.users.${username}.ryk.printing3d.enableBambuStudio = false;
    }
  ];
};
```

The override must be appended after the existing Home Manager module so it overrides the default rather than replacing any Home Manager imports or package lists.

- [ ] **Step 5: Run the regression test to verify both target contracts**

Run:

```bash
bash scripts/tests/test-vasher-bambu-exclusion.sh
```

Expected: exit 0. The real target reports `true` and contains Bambu; the prebuild target reports `false`, excludes Bambu, retains the other three 3D packages, and evaluates to a top-level derivation.

- [ ] **Step 6: Commit the configuration target**

```bash
git add modules/groups/printing3d.nix modules/hosts/jezrien/default.nix scripts/tests/test-vasher-bambu-exclusion.sh
git commit -m "feat: exclude Bambu Studio from Vasher prebuilds"
```

### Task 2: Point Vasher at the reduced target and make the exception observable

**Files:**
- Modify: `modules/hosts/vasher/_role.nix:53-59`
- Modify: `modules/nixos/vasher-prebuild.nix:19-32,87-88,114-132`
- Modify: `scripts/tests/test-vasher-bambu-exclusion.sh`

**Interfaces:**
- Consumes `ryk.vasherPrebuild.targetAttr` and new `ryk.vasherPrebuild.excludedPackages`.
- Produces status JSON with `status`, `mode`, `excludedPackages`, and the existing success/failure fields.
- Vasher's host role sets `targetAttr` to the `jezrien-prebuild` top-level path and `excludedPackages` to `[ "bambu-studio" ]`.

- [ ] **Step 1: Extend the regression test with Vasher's declared contract**

Append to `scripts/tests/test-vasher-bambu-exclusion.sh`:

```bash
target_attr=$(nix eval "$repo_root#nixosConfigurations.vasher.config.ryk.vasherPrebuild.targetAttr" --raw)
test "$target_attr" = 'nixosConfigurations.jezrien-prebuild.config.system.build.toplevel'

excluded_packages=$(nix eval "$repo_root#nixosConfigurations.vasher.config.ryk.vasherPrebuild.excludedPackages" --json)
test "$excluded_packages" = '["bambu-studio"]'
```

- [ ] **Step 2: Run the test to verify the Vasher assertions fail**

Run:

```bash
bash scripts/tests/test-vasher-bambu-exclusion.sh
```

Expected: nonzero exit because Vasher still targets real Jezrien and has no `excludedPackages` option.

- [ ] **Step 3: Add the declared exception to the prebuilder module**

In `modules/nixos/vasher-prebuild.nix`, add immediately after `KEEP_ROOTS`:

```nix
EXCLUDED_PACKAGES=${lib.escapeShellArg (builtins.toJSON cfg.excludedPackages)}
```

Replace the failure record with:

```bash
jq -n --arg mode "$mode" --argjson exitCode "$exit_code" \
  --argjson excludedPackages "$EXCLUDED_PACKAGES" \
  '{status:"failed",mode:$mode,exitCode:$exitCode,excludedPackages:$excludedPackages}' > "$status" || true
```

Replace the success record with:

```bash
jq -n --arg mode "$mode" --arg out "$out" --arg revision "$(git -C "$worktree" rev-parse HEAD)" \
  --argjson excludedPackages "$EXCLUDED_PACKAGES" \
  '{status:"success",mode:$mode,output:$out,revision:$revision,excludedPackages:$excludedPackages}' > "$status"
```

Add this option after `targetAttr`:

```nix
excludedPackages = lib.mkOption {
  type = lib.types.listOf lib.types.str;
  default = [ ];
  description = "Package names intentionally excluded from the prebuilt closure.";
};
```

- [ ] **Step 4: Configure Vasher explicitly**

Replace the single enable assignment in `modules/hosts/vasher/_role.nix` with:

```nix
ryk.vasherPrebuild = {
  enable = true;
  targetAttr = "nixosConfigurations.jezrien-prebuild.config.system.build.toplevel";
  excludedPackages = [ "bambu-studio" ];
};
```

- [ ] **Step 5: Run focused regression checks**

Run:

```bash
bash scripts/tests/test-vasher-bambu-exclusion.sh
bash scripts/tests/test-vasher-resource-policy.sh
nix build .#nixosConfigurations.jezrien-prebuild.config.system.build.toplevel --no-link
```

Expected: both scripts exit 0; the build completes without evaluating Bambu Studio as a required output. The resource-policy test still reports `max-jobs = 1` and `cores = 4`.

- [ ] **Step 6: Commit the Vasher contract**

```bash
git add modules/hosts/vasher/_role.nix modules/nixos/vasher-prebuild.nix scripts/tests/test-vasher-bambu-exclusion.sh
git commit -m "feat: report Vasher prebuild exclusions"
```

### Task 3: Deploy safely and verify one real candidate

**Files:**
- Modify: `wiki/hosts.md` only if its Vasher operations section does not already state how to deploy a changed target and inspect `last-build.json`.

**Interfaces:**
- Consumes the deployed Vasher configuration and runtime-masked units.
- Produces one candidate `last-build.json` record declaring the Bambu exclusion.

- [ ] **Step 1: Update the operator note if missing**

Add this exact paragraph to the Vasher operations section only if it is absent:

```markdown
Vasher prebuilds `nixosConfigurations.jezrien-prebuild`, which intentionally omits `bambu-studio`. A successful `last-build.json` must report `"excludedPackages":["bambu-studio"]`; Jezrien builds that package locally when promoting `cache-bump`.
```

- [ ] **Step 2: Deploy the changed Vasher role from the Proxmox host**

Run:

```bash
pct exec 200 -- /run/current-system/sw/bin/env \
  PATH=/run/current-system/sw/bin \
  /run/current-system/sw/bin/nixos-rebuild switch --refresh \
  --flake github:rykugur/dotfiles#vasher
```

Expected: NixOS activation succeeds. Do not start a prebuild before this activation completes.

- [ ] **Step 3: Unmask and start exactly one detached candidate**

Run from Jezrien:

```bash
ssh root@vasher.local.ryk.sh '
  systemctl unmask vasher-prebuild-master.service vasher-prebuild-candidate.service
  systemctl unmask vasher-prebuild-master.timer vasher-prebuild-candidate.timer
  systemctl start --no-block vasher-prebuild-candidate.service
'
```

Expected: SSH returns immediately; only the candidate runs, serialized by `/var/lib/vasher/prebuild.lock`.

- [ ] **Step 4: Verify the real candidate record before promotion**

Run from Jezrien after the unit finishes:

```bash
ssh root@vasher.local.ryk.sh '
  cat /var/lib/vasher/last-build.json
  systemctl status vasher-prebuild-candidate.service --no-pager
  free -h
'
```

Expected: status JSON is `success`; `excludedPackages` is exactly `["bambu-studio"]`; the unit exited successfully; memory is not exhausted. If it failed, leave `cache-bump` unpromoted and inspect the status plus unit journal.

- [ ] **Step 5: Commit any required operations documentation**

```bash
git add wiki/hosts.md
git commit -m "docs: record Vasher Bambu cache exception"
```

Commit only if Step 1 changed the file.

## Self-Review

- **Spec coverage:** Task 1 keeps real Jezrien unchanged, exposes the reduced target, and proves package membership. Task 2 makes Vasher use that target and places the exception in both terminal status paths. Task 3 preserves masked-until-deployed safety and proves the deployed candidate contract. Promotion, retention, timers, signing, SSH, memory, and concurrency are intentionally untouched.
- **Placeholder scan:** No unfinished work markers or unspecified tests are present. The only conditional is documentation insertion, explicitly gated by whether the exact operator statement already exists.
- **Type consistency:** `enableBambuStudio` is a Home Manager boolean; `excludedPackages` is a Nix list of strings and is serialized once to JSON before jq consumes it as `--argjson`.
