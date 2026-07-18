# Task 5 recovery report: secure Fish 1Password/SOPS helpers

## Result

- **Status:** DONE
- **Commit:** `cf35fd8e feat: port secure Fish SOPS helpers`
- **Scope:** recovered the interrupted Task 5 1Password/SOPS Fish helper suite, completion, safe abbreviation, and focused stub-only tests.

## Delivered helpers

- `__op-select-ssh-key` takes an explicit item ID or selects an ID from structured 1Password JSON via `jq` and `fzf`.
- `op-ssh-public-key`, `sops-age-public-key`, `sops-age-private-key`, and `sops-age-private-from-ssh` retain the specified streaming interfaces.
- `sops-setup-new-host [--yes] [ITEM_ID]` confirms before any destination change unless `--yes` is present.
- `sops-setup-new-host` has its `-y`/`--yes` completion, and `skaf` expands only to the safe `sops-kaf` command.

Only item IDs and filesystem paths are assigned to Fish local variables. Revealed private key material stays in pipelines and is never assigned to a Fish variable, printed for diagnostics, or placed in universal Fish state.

## Security recovery

The interrupted implementation redirected the conversion output directly to `keys.txt`. That made two failure modes possible: it could truncate an existing valid key before conversion succeeded, and it could open/follow an unsafe pre-existing destination before permissions were corrected.

The final provisioning flow is:

1. Select the item ID, then obtain confirmation before touching the destination.
2. Reject a symlinked or non-directory SOPS age directory; create or correct that directory to exact mode `0700`.
3. Reject a symlinked or non-regular `keys.txt` target, including FIFO targets.
4. Create a same-directory `.keys.txt.XXXXXX` temporary regular file under `umask 077`, verify that it is regular, and set its exact mode to `0600` before conversion output is redirected to it.
5. Stream the revealed key directly through `ssh-to-age` into that temporary file. A failure in either pipeline stage removes the temporary file and leaves the existing regular key unchanged.
6. Revalidate the destination immediately before replacement, rejecting a destination that changed into a symlink or non-regular type during conversion.
7. Use GNU `mv -fT` to atomically replace only the `keys.txt` path, never treat a directory as a destination container. A failed replacement removes the temporary file.

The temporary file and final destination are in the same directory, so the replacement is on the same filesystem. Error diagnostics include only destination paths, never key data.

## Focused test coverage

`tests/fish/op-sops.test.fish` creates temporary stubs only. It does not call real 1Password, SOPS, or key conversion services. It verifies:

- public and private conversion interfaces under stubs;
- setup output has no fixture private material;
- successful provisioning creates a regular key and uses exact directory/file modes `0700`/`0600`;
- a negative confirmation creates no key;
- cancelled `fzf` selection returns failure, leaks no private output, and creates no key;
- failed conversion preserves an existing mode-`0600` key and leaves no temporary file;
- symlink and FIFO key destinations are rejected without target replacement or private-output leakage;
- a destination changed into a directory during conversion is rejected immediately before replacement, does not receive the temporary file, and leaves no temporary file behind.

The preservation regression failed against the interrupted direct-redirection implementation before the recovery change. The destination-directory race regression failed against the initial unguarded `mv -f` recovery implementation before the final `mv -fT` and cleanup guard were added.

## Focused verification

Fish is not installed on the host PATH, so all focused checks used Nix-provided Fish:

```sh
nix shell nixpkgs#fish -c fish --no-config tests/fish/op-sops.test.fish
nix shell nixpkgs#fish -c fish --no-execute \
  configs/fish/functions/__op-select-ssh-key.fish \
  configs/fish/functions/op-ssh-public-key.fish \
  configs/fish/functions/sops-age-public-key.fish \
  configs/fish/functions/sops-age-private-key.fish \
  configs/fish/functions/sops-age-private-from-ssh.fish \
  configs/fish/functions/sops-setup-new-host.fish \
  configs/fish/completions/sops-setup-new-host.fish
```

Both commands exited successfully with no output. No formatter, broad flake check, real `op`, or real SOPS operation was run.

## Concerns

None for the Linux/Nix Fish target exercised by the focused suite. The no-target-directory replacement uses GNU `mv -T`, which is available on the stated Linux target.

## Security review follow-up: pinned staging and termination cleanup

The follow-up fixes both reviewer findings without exposing private material.

1. After the existing age-directory checks and exact `0700` mode correction, `sops-setup-new-host` saves the caller directory and enters the confirmed age directory once. Every subsequent key-target validation, `mktemp`, conversion redirection, `mv -fT`, and temporary-file removal uses `keys.txt` or `.keys.txt.XXXXXX` relative to that working directory. If the original pathname is renamed and replaced while conversion runs, Fish retains the original directory inode as its working directory; the replacement is therefore written only in that original directory.
2. Once the relative temporary regular file is verified and set to exact `0600`, the helper registers a unique Fish cleanup function for `SIGINT`, `SIGTERM`, and `fish_exit`. The handler inherits only the relative temporary name and removes that name from the still-pinned directory. It is registered before key conversion begins. Every explicit failure after registration erases the handler, removes the relative temporary name, restores the caller working directory, and returns failure. The handler is erased only after successful relative `mv -fT -- "$temporary_key_file" keys.txt`, before the caller directory is restored; it can therefore never delete a successfully renamed final `keys.txt`.
3. Handler lifetime and working-directory restoration were self-reviewed: no branch after the directory entry re-resolves `"$key_dir"` for staging, replacement, or cleanup; all normal failure branches restore the saved caller directory; the only successful branch disarms after atomic replacement and then restores it. The exit/signal handler does not `cd`, so it removes only the inherited relative temporary name while Fish remains in the pinned age directory.

Additional stub-only regressions in `tests/fish/op-sops.test.fish` verify:

- a `nix` stub renames the age directory during conversion and creates an empty replacement at its old pathname; provisioning succeeds, writes the converted key in the renamed original directory, leaves the replacement empty, and leaves no `.keys.txt.*` file in the renamed original;
- a subprocess-scoped `nix` stub sends `SIGTERM` to its Fish parent during conversion; provisioning fails without revealing fixture private material, preserves an existing `0600` key, and leaves no `.keys.txt.*` file;
- the existing failed-conversion regression continues to prove an existing key remains unchanged and no temporary file remains.

The SIGTERM regression was observed failing before the handler fix with:

```text
sops-setup-new-host left a temporary key file after SIGTERM during conversion
```

Focused Nix Fish verification after the fixes:

```sh
nix shell nixpkgs#fish -c fish --no-config tests/fish/op-sops.test.fish
nix shell nixpkgs#fish -c fish --no-execute \
  configs/fish/functions/__op-select-ssh-key.fish \
  configs/fish/functions/op-ssh-public-key.fish \
  configs/fish/functions/sops-age-public-key.fish \
  configs/fish/functions/sops-age-private-key.fish \
  configs/fish/functions/sops-age-private-from-ssh.fish \
  configs/fish/functions/sops-setup-new-host.fish \
  configs/fish/completions/sops-setup-new-host.fish
```

Both commands exited `0` with no output. The suite uses only generated `op`, `fzf`, and `nix` stubs; no real 1Password, SOPS, or private key was used. No formatter, broad check, or flake evaluation was run.

### Review correction: termination propagation and cleanup ordering

The first follow-up handler was corrected after review found that registering a Fish signal handler suppresses Fish's default termination behavior. The `SIGINT` and `SIGTERM` handlers now remove the staged relative name, erase all three cleanup handlers, and re-raise the original signal to `$fish_pid`; the process therefore terminates with the conventional `130` or `143` signal status after cleanup. The signal regression now asserts exact `143`, rather than merely a nonzero result.

The explicit post-conversion failure branches were also reordered to remove the relative staged file **before** erasing the handlers, eliminating the interruption window where private staging material could survive. On success, all handlers remain live through the relative atomic replacement and are erased only after `mv -fT` succeeds. The handlers operate solely on the inherited temporary filename, never `keys.txt`.

The focused signal regression initially failed against the swallowing handler with:

```text
sops-setup-new-host did not terminate with SIGTERM status during conversion (got 0)
```

After correction, the same focused Nix Fish suite and parser command shown above both exited `0` with no output.
