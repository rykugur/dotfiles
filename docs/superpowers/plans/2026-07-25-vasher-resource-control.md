# Vasher Resource-Control Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Vasher's nightly prebuild reliable by declaring its 12 GiB/2 GiB LXC envelope and serializing Nix derivation builds while retaining four-core throughput inside the one active build.

**Architecture:** The Proxmox bootstrap script owns reproducible CT creation arguments. Vasher's role module owns Nix daemon scheduling limits. A black-box shell test stubs `pct` and evaluates the actual NixOS configuration, so the resource contract is checked without creating a container. Host documentation defines operation, recovery, and the intentionally separate manual promotion workflow.

**Tech Stack:** NixOS modules, Proxmox `pct`, Bash, Nix CLI, jq.

## Global Constraints

- CT 200 keeps 4 cores and declares `12288` MiB RAM and `2048` MiB swap.
- Vasher's Nix daemon uses exactly `max-jobs = 1` and `cores = 4`.
- The candidate timer remains nightly; `cache-bump` promotion and Jezrien switching remain manual.
- Do not add service cgroup memory limits, change cache retention/signing, or change SSH policy.
- Use the existing `scripts/tests/test-*.sh` executable-test convention.

---

### Task 1: Add a failing resource-policy contract test

**Files:**
- Create: `scripts/tests/test-vasher-resource-policy.sh`
- Read: `scripts/bootstrap/proxmox-lxc-create.sh`
- Read: `modules/hosts/vasher/_role.nix`

**Interfaces:**
- Consumes: `scripts/bootstrap/proxmox-lxc-create.sh <template-tarball>`.
- Consumes: `nixosConfigurations.vasher.config.nix.settings` evaluated through `nix eval`.
- Produces: an executable test that exits nonzero if the CT arguments or Nix scheduling policy differ from the approved values.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test-vasher-resource-policy.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

stub_bin="$tmp/bin"
mkdir "$stub_bin"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" >> "$PCT_LOG"\n' > "$stub_bin/pct"
chmod +x "$stub_bin/pct"

PATH="$stub_bin:$PATH" PCT_LOG="$tmp/pct.log" \
  "$repo_root/scripts/bootstrap/proxmox-lxc-create.sh" \
  /var/lib/vz/template/cache/nixos-system-x86_64-linux.tar.xz

test "$(cat "$tmp/pct.log")" = "$(cat <<EOF
create
200
local:vztmpl/nixos-system-x86_64-linux.tar.xz
--hostname
vasher
--cores
4
--memory
12288
--swap
2048
--rootfs
local-lvm:100
--net0
name=eth0,bridge=vmbr0,ip=dhcp
--features
nesting=1
--unprivileged
1
--ssh-public-keys
$HOME/.ssh/authorized_keys
start
200
EOF
)"

settings=$(nix eval "$repo_root#nixosConfigurations.vasher.config.nix.settings" --json)
test "$(jq -r '."max-jobs"' <<<"$settings")" = 1
test "$(jq -r '.cores' <<<"$settings")" = 4
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash scripts/tests/test-vasher-resource-policy.sh
```

Expected: failure because the bootstrap currently passes `--memory 8192`, omits `--swap`, and the evaluated Vasher Nix settings do not yet define `max-jobs` or `cores`.

- [ ] **Step 3: Commit the failing-test checkpoint only if the repository convention requires it**

Do not commit a deliberately failing test by default. Keep the test staged locally until Task 2 makes the contract pass.

### Task 2: Declare Vasher LXC and Nix scheduling limits

**Files:**
- Modify: `scripts/bootstrap/proxmox-lxc-create.sh:5-8`
- Modify: `modules/hosts/vasher/_role.nix:12-34`
- Test: `scripts/tests/test-vasher-resource-policy.sh`

**Interfaces:**
- Consumes: the resource contract from Task 1.
- Produces: a reproducible `pct create` invocation and evaluated `nix.settings.max-jobs`/`cores` values used by the daemon and Vasher prebuild services.

- [ ] **Step 1: Update the bootstrap resource arguments**

Replace the `pct create` resource fragment with:

```bash
pct create 200 "local:vztmpl/$(basename "$image")" \
  --hostname vasher --cores 4 --memory 12288 --swap 2048 --rootfs local-lvm:100 \
```

Keep every subsequent network, nesting, unprivileged, SSH-key, and start argument unchanged.

- [ ] **Step 2: Add the Nix daemon scheduling limits**

Inside `nix.settings` in `modules/hosts/vasher/_role.nix`, immediately after `auto-optimise-store = true;`, add:

```nix
max-jobs = 1;
cores = 4;
```

Do not alter the substituter or trusted-public-key lists.

- [ ] **Step 3: Run the focused regression test**

Run:

```bash
bash scripts/tests/test-vasher-resource-policy.sh
```

Expected: exits `0`; the fake `pct` receives the exact 12 GiB/2 GiB creation contract, and the evaluated role emits the approved Nix settings.

- [ ] **Step 4: Build the deployed Vasher closure**

Run:

```bash
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```

Expected: exits `0` and prints one `nixos-system-vasher-...` store path.

- [ ] **Step 5: Commit the policy and test**

```bash
git add scripts/bootstrap/proxmox-lxc-create.sh \
  modules/hosts/vasher/_role.nix \
  scripts/tests/test-vasher-resource-policy.sh
git commit -m "fix(vasher): constrain nightly build memory"
```

### Task 3: Document deployment and operational verification

**Files:**
- Modify: `wiki/hosts.md:52-59`
- Test: `scripts/tests/test-vasher-resource-policy.sh`

**Interfaces:**
- Consumes: the committed resource settings from Task 2.
- Produces: the exact operator procedure for applying the role, confirming limits, starting a detached candidate, and recovering memory pressure.

- [ ] **Step 1: Extend the Vasher host section**

Append these bullets after the retention bullet in `wiki/hosts.md`:

```markdown
- **Resources**: CT 200 uses 4 cores, 12 GiB RAM, and 2 GiB swap. Vasher Nix limits builds to one derivation with four build cores (`max-jobs = 1`, `cores = 4`).
- **Deploy**: `ssh root@vasher.local.ryk.sh 'nixos-rebuild switch --refresh --flake github:rykugur/dotfiles#vasher'` applies the role without starting a candidate.
- **Verify**: `ssh root@vasher.local.ryk.sh 'nix config show | grep -E "^(max-jobs|cores) ="'` reports `max-jobs = 1` and `cores = 4`; `free -h` shows the CT envelope.
- **Run/recover**: start a detached candidate with `systemctl start --no-block vasher-prebuild-candidate.service`; from the Proxmox host, stop it with `pct exec 200 -- /run/current-system/sw/bin/systemctl stop vasher-prebuild-candidate.service` if memory pressure threatens the host.
```

Keep the existing nightly-candidate, manual-promotion, retention, and migration bullets unchanged.

- [ ] **Step 2: Re-run the focused regression test**

Run:

```bash
bash scripts/tests/test-vasher-resource-policy.sh
```

Expected: exits `0`.

- [ ] **Step 3: Run existing promotion-script coverage**

Run:

```bash
bash scripts/tests/test-vasher-promote.sh
```

Expected: exits `0`; this confirms the manual weekly promotion contract remains unaffected.

- [ ] **Step 4: Commit documentation**

```bash
git add wiki/hosts.md
git commit -m "docs: record Vasher resource operations"
```

### Task 4: Deploy and verify the live nightly worker

**Files:**
- Read: `modules/nixos/vasher-prebuild.nix:91-163`
- Read: `wiki/hosts.md:52-65`

**Interfaces:**
- Consumes: the merged Task 2 role configuration and the manually applied CT envelope.
- Produces: live evidence that the configured daemon limits apply and that the candidate service is detached from Jezrien's SSH session.

- [ ] **Step 1: Deploy the merged configuration from Jezrien/Nushell**

```nu
ssh root@vasher.local.ryk.sh 'nixos-rebuild switch --refresh --flake github:rykugur/dotfiles#vasher'
```

Expected: exits `0`. It installs the corrected cache signing key and the new Nix limits; it does not invoke either prebuild service.

- [ ] **Step 2: Verify the live limits and timer**

```nu
ssh root@vasher.local.ryk.sh 'nix config show | grep -E "^(max-jobs|cores) ="; systemctl list-timers vasher-prebuild-candidate.timer --no-pager'
```

Expected: `max-jobs = 1`, `cores = 4`, and an upcoming nightly candidate timer occurrence.

- [ ] **Step 3: Start one detached candidate build**

```nu
ssh root@vasher.local.ryk.sh 'systemctl start --no-block vasher-prebuild-candidate.service'
```

Expected: the SSH command returns promptly while the service continues on Vasher.

- [ ] **Step 4: Verify completion and memory behavior after the job settles**

```nu
ssh root@vasher.local.ryk.sh 'cat /var/lib/vasher/last-build.json; free -h; systemctl status vasher-prebuild-candidate.service --no-pager'
```

Expected: `last-build.json` reports `status: "success"`, memory and swap are below exhaustion, and the one-shot unit shows successful completion. If the closure itself fails for an unrelated upstream evaluation/build error, retain the failure JSON and journal; do not promote `cache-bump`.

- [ ] **Step 5: Commit deployment-independent work before live execution**

Do not commit live-service output or generated cache artifacts. Push the Task 2 and Task 3 commits before executing this task.
