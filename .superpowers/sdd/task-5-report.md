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

## Candidate publication ordering regression

### Root cause

The generated candidate script built the closure, created a root, pruned roots
beyond five, and collected garbage before committing and publishing the
candidate lock update. Both `push --force-with-lease` attempts can fail, so
that ordering released a retained root even though publication failed.

### Disposable behavioral RED→GREEN reproduction

The reproduction executed a temporary copy of the actual generated
`vasher-prebuild` wrapper. It changed only the wrapper's private
`/var/lib/vasher` state directory to a temporary directory and supplied
disposable command fakes. It seeded five retained roots, made `nix build`
succeed, created roots through the generated `nix-store --add-root` call, and
made both candidate `git push --force-with-lease` attempts fail. The generated
candidate invocation therefore exited nonzero as production does after a
failed retry; the harness then asserted every original retained root still
existed.

Before the ordering change, the real generated wrapper failed the assertion:

```text
$ /tmp/vasher-root-retention-red-HjaSkU/run-red.sh
FAIL: retained root removed: /tmp/vasher-root-retention-red-HjaSkU/state/gcroots/old-root-5
```

After the ordering change, the rebuilt generated wrapper retained all five
original roots despite both forced publication failures:

```text
$ /tmp/vasher-root-retention-green-AIfVvx/run-green.sh
PASS: all five original roots survived failed publication
```

### Focused closure verification

```sh
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```

Result: exit status `0`.

```text
/nix/store/7w7xkj4kkp0yv7mxxw28c7pfizfy4xb1-nixos-system-vasher-lxc-proxmox-26.11.20260723.e2587ca
```

### Change

- `modules/nixos/vasher-prebuild.nix`: candidate-only commit/push (including
  the existing fetch-and-retry lease push) now occurs immediately after the
  successful build and before root creation, pruning, and collection.
- Master still follows its original build → root → prune → GC flow.
- The shared lock, failure-status trap, retry semantics, and deployment
  behavior are unchanged.

### Concerns

- None.
