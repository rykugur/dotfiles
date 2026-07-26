# Task 5 Report

## Files

- Created `modules/nixos/vasher-prebuild.nix`.
- Updated `modules/hosts/vasher/default.nix` to import the scheduler after `vasher-cache`.
- Updated `modules/hosts/vasher/_role.nix` to enable `ryk.vasherPrebuild`.

## Verification

Command:

```sh
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```

Result: exit status `0`.

Output:

```text
/nix/store/cj1zmk6laz2j20yyrn8clp24dw42zr6b-nixos-system-vasher-lxc-proxmox-26.11.20260723.e2587ca
```

The closure build included and shellchecked the `vasher-prebuild` `writeShellApplication`.

## Commit

- `04c44d51 feat(vasher): prebuild master and nightly candidates`

## Self-review

- Both timers invoke separate services that call one shared nonblocking `flock`-guarded script, so master polling and nightly candidate publication cannot run concurrently.
- Each mode resets its isolated worktree to `origin/master`; only candidate updates `flake.lock`, builds the exact configured Jezrien closure, then may publish `HEAD` to `cache-bump` with the required lease retry.
- Successful builds rotate GC roots after linking the new closure and retain the configured five roots by default. Failure traps write the selected mode and original nonzero exit code to the status file.
- The deploy-key mapping and SSH command use the required `swoleflake/deploy_key` path. No secret values are recorded here.

## Review fixes

- The reusable worktree test now uses `-e`, which correctly recognizes Git's `.git` file in a linked worktree and avoids a failing second `git worktree add`.
- GC-root pruning now iterates `"${stale[@]}"`, so no removal command runs when all retained roots fit within the configured limit.
- Each successful build now registers its named root with `nix-store --add-root --indirect --realise`; removing stale named roots releases their indirect GC-root lifecycle.

## Follow-up verification

```sh
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```

Result: exit status `0`.

```text
/nix/store/cff2laf9p60725f3wa0hn99ch4xm5ksx-nixos-system-vasher-lxc-proxmox-26.11.20260723.e2587ca
```

## Follow-up commit

- `be0dd400 fix(vasher): preserve prebuild worktrees and roots`

## Concerns

- None.

## Independent focused verification

```sh
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```

Result: exit status `0`.

```text
/nix/store/57ygkdgh4kfsq5yb3s1lqaiv8fqd5bwk-nixos-system-vasher-lxc-proxmox-26.11.20260723.e2587ca
```

## Final scheduler corrections

### Root causes

- Timestamp-only root names created a distinct root for every unchanged master
  build, allowing no-op polling to spend the five-root budget.
- Candidate publication happened before its root was registered, so a root
  registration failure could publish an unretained closure. The former repair
  also performed root rotation before publication, so a failed push could
  discard a retained root.
- Both modes used a nonblocking lock; a candidate scheduled while a master
  build held it exited successfully without running.

### Disposable generated-wrapper RED→GREEN reproductions

Each harness copied the generated `vasher-prebuild` wrapper, changed only its
private `/var/lib/vasher` directory to a disposable state directory, and
prepended disposable fake external commands. It exercised the copied wrapper,
not a hand-written model. No network, deployment, or real garbage collection
was performed.

| Invariant | RED: prior wrapper | GREEN: corrected wrapper |
| --- | --- | --- |
| Repeated no-op master builds retain one root for an unchanged output/revision | `/tmp/vasher-unique-roots-red-P34bll/run.sh` exited 1: `FAIL: repeated no-op master build retained 2 roots` | `/tmp/vasher-unique-roots-green-aKzJ9z/run.sh` exited 0: `PASS: repeated no-op master build retained one root` |
| Root-registration failure prevents candidate publication | `/tmp/vasher-candidate-root-red-x3U6MA/run.sh` exited 1: `FAIL: candidate published despite root registration failure` | `/tmp/vasher-candidate-root-green-Odhshn/run.sh` exited 0: `PASS: root registration failure prevented publication` |
| Failed candidate publication retains its new root, retains the prior five roots, and does not GC | `/tmp/vasher-candidate-push-red-loXpIM/run.sh` exited 1: `FAIL: failed publication did not retain its new root (found 5 roots)` | `/tmp/vasher-candidate-push-green-84VLbo/run.sh` exited 0: `PASS: failed publication kept new and existing roots without GC` |
| Candidate waits behind the shared lock | `/tmp/vasher-candidate-lock-red-4wU2Dj/run.sh` exited 1: `FAIL: candidate skipped while the shared lock was held` | `/tmp/vasher-candidate-lock-green-MMmnmK/run.sh` exited 0: `PASS: candidate waited for the shared lock and then built` |

The updated generated wrapper was also run under a held lock in master mode:

```text
$ /tmp/vasher-master-coalesce-uQYOgr/run.sh
PASS: master coalesced without starting a build
```

### Focused closure verification

```sh
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```

Result: exit status `0`.

```text
/nix/store/rm3h17wl9gn6p0d77iq17w83351gbz6d-nixos-system-vasher-lxc-proxmox-26.11.20260723.e2587ca
```

### Change

- Roots are keyed only by the built store-output basename, so an output retains
  one stable root across Git revisions.
- Candidate commits its lockfile update, registers the keyed root, then uses
  the existing two-attempt lease push. Root pruning and collection happen only
  after that publication succeeds.
- Master keeps its nonblocking coalescing lock; candidate now blocks on the
  same lock before its work begins. The status trap, sandbox, service/timer
  names, and push retry are unchanged.

## Output-unique, recency-safe root correction

### Root cause

- Prefixing root names with the Git revision created duplicate roots for one
  store output when its source revision changed.
- Reusing an existing root left its symlink timestamp unchanged, allowing that
  current output to become the oldest root and be pruned during a later
  rotation.

### Disposable generated-wrapper RED→GREEN reproductions

Each harness copied the generated `vasher-prebuild` wrapper, redirected only
its private `/var/lib/vasher` state to a temporary directory, and prepended
disposable fake external commands. No network, deployment, store mutation, or
real garbage collection was performed.

| Invariant | RED: prior wrapper | GREEN: corrected wrapper |
| --- | --- | --- |
| One output built at two Git revisions has one root | `FAIL: same output at two revisions retained 2 roots` | `PASS: same output at two revisions retained one root` |
| A reused output survives the next new-output rotation after five roots | `FAIL: reused output a was pruned during later rotation` | `PASS: reused output a survived later rotation` |

### Focused closure verification

```sh
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```

Result: exit status `0`.

