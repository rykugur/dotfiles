# Task 3 Report — Fish utility helpers

## Result

Committed Task 3 as `812e0ad5 feat: port Fish utility helpers`.

Implemented the requested 20 one-function Fish helper files:

- Git: `gas`, `gcu`, `gbz`, `gcoz`
- rebuild/Nix: `rbld`, `rbld-switch`, `rbld-boot`, `nix-get-hash`, `nrd`, `nrf`, `nrun`, `mkenvrc`, `mkflake`, `mkflake-electrobun`
- generic/clipboard: `stay-awake`, `cmd-copy`, `cmd-paste`, `replace-multiline`, `paste-multiline`, `edit-multiline`

Added `tests/fish/helpers-load.test.fish` exactly as specified. Removed the obsolete Fish `nrf` abbreviation and `cmd.copy`/`cmd.paste` eval aliases; `shash` now delegates to `nix-get-hash`, and relevant clipboard abbreviations use `cmd-copy`. `configs/fish/ez/git.fish` and `configs/fish/ez/linux.fish` were inspected but required no change: they had no conflicting obsolete helper shim or duplicate stateful helper.

## TDD evidence

1. Added the requested load test before helper implementation.
2. The required direct command could not execute because `fish` is not installed on the base PATH:

   ```text
   fish --no-config tests/fish/helpers-load.test.fish
   error: command not found: fish
   ```

3. Verified the same test with locally available Nix-provided Fish 4.8.0 before implementation:

   ```sh
   nix shell nixpkgs#fish -c fish --no-config tests/fish/helpers-load.test.fish
   ```

   It failed as expected with `missing function: gas` and exit status 1.

4. After implementation, the same Nix-provided command completed successfully with exit status 0 and no output.

## Focused verification

All verification was scoped to Task 3; no project-wide formatter, build, or test suite was run.

| Check | Result |
| --- | --- |
| `nix shell nixpkgs#fish -c fish --version` | Fish 4.8.0 available locally through Nix. |
| `fish --no-execute` for every `configs/fish/functions/*.fish` file, run through `nix shell nixpkgs#fish` because base PATH lacks Fish | Exit 0; no parser output. |
| `nix shell nixpkgs#fish -c fish --no-config tests/fish/helpers-load.test.fish` | Exit 0; all 20 declared functions load after `config.fish`. |
| Focused temporary Fish smoke test, run with Nix Fish and deleted after verification | Exit 0. It exercised NUL-safe `gas` for `AM` and `MM` paths containing newlines, NUL-safe `gcu` deletion of an untracked newline-containing path, `gbz` selection and `gcoz` checkout with a stubbed `fzf`, Linux dispatch for `rbld`, `nrun`, `nix-get-hash`, `nrd`, remote `nrf`, and `stay-awake` with stub executables, Linux clipboard copy/paste, multiline replacement/execution/editor flow, `mkenvrc` content, and both flake-template copies. |

## Fish API/syntax resolution

The base environment had no `fish` executable, so Fish 4.8.0 from the existing local Nix package set was used for all runnable checks. Official Fish documentation was consulted for `read --null`, `string replace --regex`, `argparse`, and `string collect`.

During focused smoke testing, two Fish-specific issues were found and fixed:

- `status` is a special Fish variable and cannot be locally assigned. `gas` now uses `porcelain_status`.
- Command substitutions do not consume the enclosing function pipeline's stdin. `replace-multiline` and `edit-multiline` now use direct `read --null content`; the multiline regex is escaped for Fish's string parsing and correctly removes a literal backslash plus line break and following indentation.

## Self-review

- Each requested helper has exactly one function in a matching helper file.
- `gas` and `gcu` consume `git status --porcelain=v1 -z` records with `read --null`; paths are passed after `--`.
- `rbld`, `rbld-switch`, `rbld-boot`, and `nrun` match the required signatures and return behavior.
- Clipboard helpers dispatch only to Linux `wl-copy`/`wl-paste` or Darwin `pbcopy`/`pbpaste`, and explicitly fail on unknown platforms.
- `mkenvrc` writes literal content with `printf`; no eval is used.
- `paste-multiline` executes the rewritten command in a Fish subprocess, never through `nu -c`.
- A scoped search found no residual `cmd.copy`, `cmd.paste`, `abbr --add --global nrf`, or `nu -c` under `configs/fish`.

## Concern

The brief's literal `fish ...` commands remain unavailable on the base PATH due to the missing `fish` executable. Equivalent checks were run successfully using the local Nix-provided Fish 4.8.0; no repository change was made to install Fish.

## Review-finding fix

Addressed the post-Task-3 review findings:

- `gcu` now uses `git ls-files --others --exclude-standard -z`, so it receives only untracked paths and cannot interpret a rename/copy source record as an untracked status entry.
- `gas` consumes the following NUL record whenever a porcelain status contains `R` or `C`, before evaluating its `AM`/`MM` staging rule.
- `shash <url>` captures the single hash printed by `nix-prefetch-url` and passes it as the quoted positional hash argument to `nix hash to-sri --type sha256`.
- Added the committed focused regression test `tests/fish/helpers-behavior.test.fish`. Its stubs prove that a rename source named `?? victim` is not acted on, copy/rename sources named `AM payload` and `MM payload` are not staged, ordinary `AM`/`MM` paths are still staged, and `shash` preserves both its URL input and its exact positional Nix hash argument.

### Initial test evidence

The following initial evidence predates the positional-argument correction documented below. Its `gcu` and rename/copy parser regressions remain covered by the current behavior test:

```text
gcu acted on a rename source named ?? victim
gas acted on rename/copy sources named AM payload or MM payload
```

Final focused verification used Nix-provided Fish only:

```sh
nix shell nixpkgs#fish -c fish --no-config tests/fish/helpers-load.test.fish && nix shell nixpkgs#fish -c fish --no-config tests/fish/helpers-behavior.test.fish
```

Result: exit status 0 with no output.

### Fix self-review

- The `gcu` Git query is NUL-delimited and untracked-only; every emitted pathname is passed to `rm` after `--`.
- `gas` reads and discards exactly one source pathname for every rename/copy porcelain entry, so source records cannot become later status fields.
- The regression test exercises embedded spaces in all relevant paths and checks behavior through executable stubs rather than source text.
- The `shash` stub verifies its URL argument, the complete Nix subcommand argument vector, and the positional prefetched hash; it does not accept a stdin pipeline.

## Re-review corrections

Addressed all four subsequent Task 3 re-review findings:

- `shash` now captures `nix-prefetch-url` output in `prefetched_hash` and supplies it as the quoted fifth argument to `nix hash to-sri --type sha256`.
- `gas` quotes the `string sub` command substitution passed after `git add --`, preserving a pathname with a literal newline as one argument.
- `replace-multiline` and `edit-multiline` now select clipboard content immediately under `test -t 0`; they call `read --null` only when standard input is piped or redirected.
- `mkenvrc` returns status 1 without changing `.envrc` when a regular file or symlink already exists.

### Focused boundary tests

`tests/fish/helpers-behavior.test.fish` now uses executable stubs and tests these observable boundaries:

- `gas` receives an `AM` pathname containing a literal newline; the stub rejects any `git add` invocation other than exactly `git add -- <one pathname>`.
- `shash` records all Nix arguments and requires `sha256-from-prefetch` as the positional argument after `sha256`.
- Both multiline helpers receive NUL-delimited piped content and must preserve it; a terminal-backed subprocess with a two-second hard timeout must instead return the clipboard content without waiting for stdin.
- `mkenvrc` must preserve an existing `.envrc`, return nonzero, and still create one when it is absent.

The expanded behavior test was run before each production correction. Its observed red failures were:

```text
gas split a newline-containing pathname passed to git add
shash did not pass nix-prefetch-url output to nix hash to-sri
replace-multiline or edit-multiline did not use the clipboard immediately on interactive stdin
mkenvrc overwrote an existing .envrc
```

### Exact final verification

All checks used Nix-provided Fish 4.8.0:

```sh
nix shell nixpkgs#fish -c fish --no-execute configs/fish/functions/gas.fish
nix shell nixpkgs#fish -c fish --no-execute configs/fish/functions/replace-multiline.fish
nix shell nixpkgs#fish -c fish --no-execute configs/fish/functions/edit-multiline.fish
nix shell nixpkgs#fish -c fish --no-execute configs/fish/functions/mkenvrc.fish
nix shell nixpkgs#fish -c fish --no-execute configs/fish/ez/nixos.fish
nix shell nixpkgs#fish -c fish --no-execute tests/fish/helpers-behavior.test.fish
nix shell nixpkgs#fish -c fish --no-config tests/fish/helpers-load.test.fish && nix shell nixpkgs#fish -c fish --no-config tests/fish/helpers-behavior.test.fish
```

Every parser check and both focused test files exited 0 with no output.

### Re-review self-review

- The captured Nix hash is a single quoted argument; no stdin pipeline remains in `shash`.
- The quoted `gas` command substitution is the only change to its pre-existing NUL-record parser and preserves status handling.
- The multiline helpers preserve their prior empty-input clipboard fallback while avoiding a terminal read.
- The `.envrc` guard precedes the only write and also protects a dangling symlink.
