# Task 6 Report: Project and Game Helper Port

## Scope completed

- Added dashed Fish functions for every helper sourced from `configs/nu/eve.nu`, `configs/nu/pz.nu`, `configs/nu/stalker2.nu`, and `configs/nu/starcitizen.nu`.
- Added `tests/fish/project-helpers-load.test.fish`, which sources the Fish configuration and asserts all 14 Task 6 functions exist.
- Appended the final command-equivalence matrix to `docs/superpowers/specs/2026-07-16-fish-migration-design.md`. It inventories every function, alias, and abbreviation sourced by `configs/nu/config.nu`; it records no intentionally Nu-only entry.
- Updated `configs/fish/exports.fish` to initialize `LOCAL_CONFIG_FILE` to `$HOME/.local/fish/config.fish` when unset; game paths remain computed inside their helpers rather than added as universal variables.

## TDD evidence

1. Added the load test before any Task 6 function implementation.
2. `fish --no-config tests/fish/project-helpers-load.test.fish` could not run because `fish` is not installed on the host `PATH` (`command not found: fish`, exit 127).
3. Ran the same test through the Nix Fish package before implementation:

   ```sh
   nix run nixpkgs#fish -- --no-config tests/fish/project-helpers-load.test.fish
   ```

   It failed as expected with `missing function: eve-pfx` (exit 1).
4. Implemented the minimal Fish functions and reran the same Nix command successfully.

## Final verification

The following focused Nix Fish checks completed successfully with no output and exit 0:

```sh
nix run nixpkgs#fish -- --no-config tests/fish/project-helpers-load.test.fish
nix run nixpkgs#fish -- --no-execute \
  configs/fish/functions/eve-pfx.fish \
  configs/fish/functions/eve-settings.fish \
  configs/fish/functions/eve-pi-templates.fish \
  configs/fish/functions/eve-gits.fish \
  configs/fish/functions/eve-eanm.fish \
  configs/fish/functions/eve-custom-ship-labeler.fish \
  configs/fish/functions/eve-pi-template-name.fish \
  configs/fish/functions/pz-copy-mod-config.fish \
  configs/fish/functions/pz-mods.fish \
  configs/fish/functions/stalker2-pfx.fish \
  configs/fish/functions/stalker2-cd.fish \
  configs/fish/functions/stalker2-mods.fish \
  configs/fish/functions/starcitizen-wine-path.fish \
  configs/fish/functions/starcitizen-controller-settings.fish
```

A focused scan of the new project helper files found no `nu -c` or `fish -c` invocation. The load test sources definitions only; it does not invoke Steam, SSH, `scp`, game executables, or system-changing commands.

## Behavioral review

- EVE prefix access rejects non-Linux before attempting `cd`; EVE settings and PI template paths retain the Nu Linux/macOS split.
- EVE EANM removes one `.local` suffix occurrence from `hostname`, enters the matching settings directory, then retains the Zulu/JAR command. PI template names are processed by `jq -r '.Cmt | gsub(" "; "")'`.
- PZ configuration copy defaults to `jezrien`, refuses a current-host prefix, and makes two direct `scp` calls without `eval`, `nu -c`, or `fish -c`.
- PZ and Stalker 2 retain their Nu Steam roots. Star Citizen helpers print the existing guidance only.

## Concern

The host does not expose a standalone `fish` executable, so all focused tests and parser checks used the installed `nixpkgs#fish` package. No functional concern remains from that substitution.

## Review remediation

Addressed every finding from `FishProjectHelpersReviewer`:

- `pz-copy-mod-config` now sends literal `HOST:~/Zomboid/Lua/...` sources while retaining expanded local destinations.
- `eve-eanm` uses `pushd`/`popd`, restores the invoking directory after both success and JAR failure, and returns the JAR status.
- `dots` now accepts Nu-compatible `--edit`/`-e` and `--local`/`-l`; local mode creates `$LOCAL_CONFIG_FILE` (`$HOME/.local/fish/config.fish` by default), enters its directory, and edits it when requested.
- Added parameterized `is-os OS`, plus `is-linux`, `is-macos`, and `is-darwin` wrappers; they compare `uname`, with `macos` and `darwin` both matching Darwin.
- Added `curl-multiline`, which removes line continuations and parses the edited leading-`curl` text into a quoted Fish argument vector without `nu -c`, `fish -c`, or shell evaluation.
- Restored `nd SHELL` (`nix develop "$DOTFILES_DIR#SHELL"`), `shash URL REV` (`nix-prefetch-git --url URL --rev REV`), and `nr.` (`nix repl --expr "builtins.getFlake \"(pwd)\""`).
- Restored `git.tree`, `git.head`, and `ll` to their Nu command arguments (`git log --graph`, `gll --oneline -1`, and `command ls -al`).
- Replaced the `psw` grep abbreviation with a Fish field predicate helper. The matrix explicitly marks the unavoidable syntax/output difference: Fish requires shell-redirection operators to be quoted and returns `ps -eo` records rather than a Nushell table.
- Restored `zellij-exists` regex matching; `zellij-create-or-attach` now follows the Nu substring/regex attach branch.
- Updated the equivalence matrix with exact option/argument behavior and the `psw` partial disposition.

## Regression coverage and evidence

- Added `tests/fish/task-6-parity.test.fish`. It stubs `scp`, `nix`, `curl`, `git`, `ls`, `ps`, and `zellij`, then covers remote tilde preservation; EANM cwd/status on success and failure; both dots short/long options; OS aliases; quoted multiline curl arguments; Git/`ll`; structured `psw`; regex zellij attach; `nd`; and `nr.`.
- Updated `tests/fish/helpers-behavior.test.fish` with the `shash URL REV`/`nix-prefetch-git` contract. Its pseudo-terminal child now uses `status fish-path`, so it remains runnable when Fish is supplied by Nix rather than the host `PATH`.
- Fresh focused verification completed with exit 0:

  ```sh
  nix run nixpkgs#fish -- --no-config tests/fish/task-6-parity.test.fish
  nix run nixpkgs#fish -- --no-config tests/fish/helpers-behavior.test.fish
  nix run nixpkgs#fish -- --no-config tests/fish/project-helpers-load.test.fish
  nix run nixpkgs#fish -- --no-execute \
    configs/fish/functions/pz-copy-mod-config.fish \
    configs/fish/functions/eve-eanm.fish \
    configs/fish/functions/dots.fish \
    configs/fish/functions/is-os.fish \
    configs/fish/functions/is-linux.fish \
    configs/fish/functions/is-macos.fish \
    configs/fish/functions/is-darwin.fish \
    configs/fish/functions/curl-multiline.fish \
    configs/fish/functions/psw.fish \
    configs/fish/functions/zellij-exists.fish \
    configs/fish/exports.fish \
    configs/fish/ez/nixos.fish \
    configs/fish/ez/git.fish \
    configs/fish/ez/misc.fish
  ```

- The new regressions invoke only local stubs; no SSH, SCP, game, or real Nix development operations ran. A focused source scan of the repaired PZ, EANM, and curl helpers found no `nu -c` or `fish -c`.

## Follow-up parity review evidence

- `psw` now captures exactly the five `ps -eo pid=,comm=,pcpu=,pmem=,args=` fields with whitespace-aware matching before it applies CPU, memory, or command predicates. The regression uses normal leading record padding plus a tab field separator and covers all three predicates.
- Added argument-taking `shlink-create`, `ghostty-fix-terminfo`, `1password-copy-ssh-pub-key`, and `proxmox-install-helix` functions. The regression records their argument vectors and the two SSH pipeline payloads with local stubs.
- Aligned `getmyip`, `cat`, `dfh`, `tmat`, and `top` with their Nu commands. `pagi` now matches only the `comm` process-name field; its unavoidable record-vs-table difference is explicitly partial. `curl-multiline` is explicitly partial because its safe tokenizer keeps Nu expressions such as `$env.API_URL` literal instead of evaluating them.
- The matrix now defines every unannotated mapping as exact and labels each differing mapping partial or intentionally non-equivalent. It contains no intentionally non-equivalent entries.
- Fresh focused verification completed with no output and exit 0:

  ```sh
  nix run nixpkgs#fish -- --no-config tests/fish/task-6-parity.test.fish
  nix run nixpkgs#fish -- --no-config tests/fish/project-helpers-load.test.fish
  nix run nixpkgs#fish -- --no-execute \
    configs/fish/functions/psw.fish \
    configs/fish/functions/pagi.fish \
    configs/fish/functions/shlink-create.fish \
    configs/fish/functions/ghostty-fix-terminfo.fish \
    configs/fish/functions/1password-copy-ssh-pub-key.fish \
    configs/fish/functions/proxmox-install-helix.fish \
    configs/fish/ez/linux.fish \
    configs/fish/ez/misc.fish
  ```

- The follow-up regression invokes only local stubs; it does not contact Kubernetes, SSH hosts, 1Password, Shlink, Proxmox, or game services.
