# Fish Dual-Shell Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a complete Fish configuration available alongside the active Nushell login shell, then allow a verified clean cutover to Fish with native completions and secure 1Password/SOPS helpers.

**Architecture:** Add an opt-in Fish trial gate to Home Manager so Fish and Nushell coexist. Port interactive behavior into the existing Fish split—simple expansions in `ez/`, stateful helpers in one-function-per-file under `functions/`—and use Fish’s native completion mechanism plus Carapace. The security-sensitive 1Password/SOPS path selects stable item IDs, streams private material, and creates the SOPS key with owner-only permissions.

**Tech Stack:** Nix/Home Manager, Fish, Carapace, 1Password CLI (`op`), `fzf`, `jq`, `nix run nixpkgs#ssh-to-age`, `sops`, `kubectl`/`kubecolor`, Zellij.

## Global Constraints

- Keep `ryk.defaultShell = "nushell"` throughout the trial; this is a dual-shell transition, not a login-shell cutover.
- Define Fish custom commands with dashed single-token names. Do not shadow `op`, `sops`, or `zellij` with namespace-dispatch functions.
- Do not call `nu -c` or source Nu configuration from Fish.
- Private SSH or age-key material MUST NOT be logged, echoed by status output, written to universal Fish variables, or committed.
- Private material may stream from `op` to `ssh-to-age`, or to the explicitly confirmed `~/.config/sops/age/keys.txt` destination only.
- Keep owner-only SOPS storage permissions: directory `0700`, key file `0600`.
- Herdr completion uses its generated Fish script; do not bridge it through Carapace.
- Every helper sourced by `configs/nu/config.nu` must receive a Fish equivalent or an explicit intentional Nu-only disposition before the login-shell flip.

---

## File map

| Path | Responsibility |
| --- | --- |
| `modules/shell/default-shell.nix` | Define a temporary `ryk.enableFishTrial` option. |
| `modules/shell/fish.nix` | Enable Fish for the normal Fish default shell or the temporary trial. |
| `modules/ai/herdr.nix` | Generate Herdr’s Fish completion only when Fish is enabled. |
| `configs/fish/exports.fish` | Reconcile environment variables consumed by ported Fish helpers. |
| `configs/fish/ez/{docker,git,linux,nixos,misc}.fish` | Reconcile existing simple Fish abbreviations/aliases with active Nu behavior. |
| `configs/fish/functions/__op-select-ssh-key.fish` | Select or validate an SSH-key item ID without exposing key material. |
| `configs/fish/functions/{op-ssh-public-key,sops-age-public-key,sops-age-private-key,sops-age-private-from-ssh,sops-setup-new-host}.fish` | OnePassword/SOPS public interfaces. |
| `configs/fish/functions/{k8s-base64,kubemerge,talosmerge,sops-kaf,zellij-*}.fish` | Port stateful Kubernetes and Zellij helpers. |
| `configs/fish/functions/{eve-*,pz-*,stalker2-*,starcitizen-*}.fish` | Port project/game helpers that Nu currently sources at startup. |
| `configs/fish/completions/*.fish` | Custom completions for Fish functions with flags/subcommands. |
| `tests/fish/*.test.fish` | Dependency-free behavioral tests, run with `fish --no-config`. |
| `docs/superpowers/specs/2026-07-16-fish-migration-design.md` | Add the final command-equivalence matrix and record explicitly retained Nu-only behavior. |

### Task 1: Enable the reversible Fish trial

**Files:**
- Modify: `modules/shell/default-shell.nix:3-17`
- Modify: `modules/shell/fish.nix:3-25`
- Modify: `modules/ai/herdr.nix:3-36`
- Test: `tests/fish/trial-module.test.sh`

**Interfaces:**
- Consumes: existing `ryk.defaultShell` enum and `programs.fish.enable`.
- Produces: `ryk.enableFishTrial :: bool`; Fish and Nu can both be enabled until the cutover.

- [ ] **Step 1: Write the Nix evaluation test**

Create `tests/fish/trial-module.test.sh`:

```sh
#!/usr/bin/env sh
set -eu

nix eval --raw .#nixosConfigurations."$(hostname -s)".config.programs.fish.enable \
  | grep -qx true
nix eval --raw .#nixosConfigurations."$(hostname -s)".config.programs.nushell.enable \
  | grep -qx true
```

Temporarily enable the trial in the active host profile before running this test. Do not change `ryk.defaultShell`.

- [ ] **Step 2: Run the test to verify the current configuration fails**

Run: `sh tests/fish/trial-module.test.sh`

Expected: the Fish evaluation returns `false` while Nushell remains enabled.

- [ ] **Step 3: Define the trial option and wire it into Fish activation**

In `modules/shell/default-shell.nix`, add this option beside `ryk.defaultShell`:

```nix
options.ryk.enableFishTrial = lib.mkOption {
  type = lib.types.bool;
  default = false;
  description = "Enable Fish alongside the configured login shell during migration.";
};
```

In `modules/shell/fish.nix`, replace the guard with:

```nix
lib.mkIf (config.ryk.defaultShell == "fish" || config.ryk.enableFishTrial) {
```

Set `ryk.enableFishTrial = true;` in the active host/profile configuration. Do not set `ryk.defaultShell = "fish"` yet.

- [ ] **Step 4: Generate Herdr’s native Fish completion during activation**

Change the returned attributes in `modules/ai/herdr.nix` to append this conditional activation entry:

```nix
// lib.optionalAttrs config.programs.fish.enable {
  home.activation.installHerdrFishCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/fish/completions"
    run sh -c '${config.programs.herdr.package}/bin/herdr completion fish > "$HOME/.config/fish/completions/herdr.fish"'
  '';
}
```

Keep the existing OMP activation unchanged. This writes a generated Fish completion file after Home Manager writes configuration and only when Fish is active.

- [ ] **Step 5: Run Nix syntax and trial evaluation checks**

Run:

```sh
nix flake check --no-build
sh tests/fish/trial-module.test.sh
```

Expected: flake evaluation succeeds; both shell enablement values are `true` during the trial.

- [ ] **Step 6: Commit the reversible activation layer**

```sh
git add modules/shell/default-shell.nix modules/shell/fish.nix modules/ai/herdr.nix tests/fish/trial-module.test.sh
git commit -m "feat: enable Fish migration trial"
```

### Task 2: Reconcile Fish environment and simple expansions

**Files:**
- Modify: `configs/fish/exports.fish:4-27`
- Modify: `configs/fish/ez/docker.fish`
- Modify: `configs/fish/ez/git.fish`
- Modify: `configs/fish/ez/linux.fish`
- Modify: `configs/fish/ez/nixos.fish`
- Modify: `configs/fish/ez/misc.fish`
- Test: `tests/fish/abbreviations.test.fish`

**Interfaces:**
- Consumes: `$HOME`, Fish’s `abbr` facility, existing Fish abbreviation files.
- Produces: all simple current Nu expansions have a Fish abbreviation/alias with equivalent command semantics.

- [ ] **Step 1: Write a loading and abbreviation regression test**

Create `tests/fish/abbreviations.test.fish`:

```fish
#!/usr/bin/env fish
set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -gx DOTFILES_DIR $repo
source $repo/configs/fish/config.fish

for abbreviation in dc ga k nb
    abbr --query $abbreviation
    or begin
        echo "missing abbreviation: $abbreviation" >&2
        exit 1
    end
end
```

This regression test covers only simple abbreviations; Task 4 tests the dashed `sops-kaf` function directly.

- [ ] **Step 2: Run the test to establish the current gaps**

Run: `fish --no-config tests/fish/abbreviations.test.fish`

Expected: failure for Nu-only current expansions such as `k` or newly required Nix aliases.

- [ ] **Step 3: Reconcile exports and static aliases without semantic rewrites**

Add these exports to `configs/fish/exports.fish`:

```fish
set -gx GITS_DIR $HOME/gits
set -gx DOTFILES_DIR $HOME/.dotfiles
set -gx NIXPKGS_ALLOW_UNFREE 1
set -gx STEAM_LIBRARY_DIR $HOME/.local/share/steam
set -gx NH_FLAKE $DOTFILES_DIR
```

Port only simple Nu expansion-map entries into their matching existing `ez` file. Use Fish abbreviations rather than aliases for commands intended to expand visibly. Preserve the currently working Fish forms when they already match Nu behavior; add missing current entries such as `gitch`, `gdstat`, `gcof`, `snrb*`, `dcu*`, `sc.*`, `za`, `zj`, `pn`, and the current pacman shortcuts.

Use real Fish command substitutions. For example, replace the Nu-only `gpub` expansion with:

```fish
abbr --add --global gpub 'git push -u origin (git.branch)'
```

Do not duplicate functions such as `gas`, `gcu`, or `gbz` as abbreviations; Task 3 ports those as functions.

- [ ] **Step 4: Run parser and abbreviation tests**

Run:

```sh
for file in configs/fish/config.fish configs/fish/exports.fish configs/fish/ez/*.fish; do fish --no-execute "$file"; done
fish --no-config tests/fish/abbreviations.test.fish
```

Expected: every file parses; each asserted abbreviation is registered after config loading.

- [ ] **Step 5: Commit the simple expansion reconciliation**

```sh
git add configs/fish/exports.fish configs/fish/ez tests/fish/abbreviations.test.fish
git commit -m "feat: reconcile Fish command abbreviations"
```

### Task 3: Port non-secret Git, Nix, and generic stateful helpers

**Files:**
- Create: `configs/fish/functions/{gas,gcu,gbz,gcoz,rbld,rbld-switch,rbld-boot,nix-get-hash,nrd,nrf,nrun,mkenvrc,mkflake,mkflake-electrobun,stay-awake,cmd-copy,cmd-paste,replace-multiline,paste-multiline,edit-multiline}.fish`
- Modify: `configs/fish/ez/{git,nixos,misc,linux}.fish`
- Test: `tests/fish/helpers-load.test.fish`

**Interfaces:**
- Consumes: the Fish environment from Task 2, `git`, `nh`, `nix`, clipboard tools, and `$EDITOR`.
- Produces: dashed or existing single-token Fish commands matching Nu’s non-secret stateful behavior.

- [ ] **Step 1: Write the function-load test**

Create `tests/fish/helpers-load.test.fish`:

```fish
#!/usr/bin/env fish
set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -gx DOTFILES_DIR $repo
source $repo/configs/fish/config.fish

for name in gas gcu gbz gcoz rbld rbld-switch rbld-boot nix-get-hash nrd nrf nrun mkenvrc mkflake mkflake-electrobun stay-awake cmd-copy cmd-paste replace-multiline paste-multiline edit-multiline
    functions --query $name
    or begin
        echo "missing function: $name" >&2
        exit 1
    end
end
```

- [ ] **Step 2: Run the test to verify the helpers are absent**

Run: `fish --no-config tests/fish/helpers-load.test.fish`

Expected: failure naming the first unported Nu function.

- [ ] **Step 3: Implement direct Fish equivalents**

Implement one named function per file. Preserve observable Nu semantics, with these signatures:

```fish
function rbld
    argparse -n rbld b/boot -- $argv; or return
    if set -q _flag_boot
        rbld-boot
    else
        rbld-switch
    end
end

function rbld-switch
    if test (uname) = Darwin
        nh darwin switch $DOTFILES_DIR
    else
        nh os switch $DOTFILES_DIR
    end
end

function rbld-boot
    if test (uname) = Darwin
        echo 'darwin-rebuild does not support boot' >&2
        return 1
    end
    nh os boot $DOTFILES_DIR
end

function nrun
    test (count $argv) -eq 1; or return 2
    nix run "nixpkgs#$argv[1]"
end
```

For `gas` and `gcu`, keep the existing Nu semantics—stage `AM`/`MM` files and delete untracked files only—but use NUL-safe Git output (`git status --porcelain=v1 -z`) and iterate with `read --null`. For clipboard helpers, preserve Linux `wl-copy`/`wl-paste` and Darwin `pbcopy`/`pbpaste`; return a nonzero status on other platforms. Implement `mkenvrc` with a literal here-string or `printf`, not an eval.

- [ ] **Step 4: Run parser and load tests**

Run:

```sh
for file in configs/fish/functions/*.fish; do fish --no-execute "$file"; done
fish --no-config tests/fish/helpers-load.test.fish
```

Expected: all files parse and all declared helpers load.

- [ ] **Step 5: Commit the non-secret function port**

```sh
git add configs/fish/functions configs/fish/ez tests/fish/helpers-load.test.fish
git commit -m "feat: port Fish utility helpers"
```

### Task 4: Port Kubernetes and Zellij helpers with dashed commands

**Files:**
- Create: `configs/fish/functions/{kubemerge,talosmerge,sops-kaf,k8s-base64,zellij-exists,zellij-create-or-attach,zellij-fzf,zellij-delete-all-sessions,zellij-murder-all-sessions}.fish`
- Create: `configs/fish/completions/{sops-kaf,k8s-base64,zellij-create-or-attach}.fish`
- Modify: `configs/fish/ez/misc.fish`
- Test: `tests/fish/k8s-zellij.test.fish`

**Interfaces:**
- Consumes: `kubecolor`, `kubectl`, `sops`, `zellij`, Fish `complete`.
- Produces: Fish commands `sops-kaf FILE`, `k8s-base64 [TOKEN]`, and `zellij-*` helpers; command names are completed by Fish and custom flags are completed explicitly.

- [ ] **Step 1: Write tests using stub executables**

Create `tests/fish/k8s-zellij.test.fish` that prepends a temporary `bin` directory to `PATH`, writes stubs for `sops`, `kubectl`, and `base64`, sources the helper files, and asserts:

```fish
printf token | k8s-base64 | string match -q 'encoded:token'
sops-kaf missing.yaml; and exit 1
```

The stubbed `sops` writes `decrypted:$argv[2]`; the stubbed `kubectl` records `apply -f -` and its stdin. Assert that `sops-kaf` rejects a nonexistent file before invoking either stub, then succeeds for a temporary file and pipes decrypted content to `kubectl apply -f -`.

- [ ] **Step 2: Run the test to verify the helpers do not exist**

Run: `fish --no-config tests/fish/k8s-zellij.test.fish`

Expected: command-not-found failure for `k8s-base64` or `sops-kaf`.

- [ ] **Step 3: Implement the Kubernetes helpers**

`k8s-base64` accepts at most one argument; if absent, it reads standard input, errors when empty, and emits no wrapping newline:

```fish
function k8s-base64
    test (count $argv) -le 1; or return 2
    set -l token $argv[1]
    if test -z "$token"
        set token (string collect)
    end
    test -n "$token"; or begin; echo 'No token provided.' >&2; return 2; end
    printf %s "$token" | base64 -w 0
end
```

` sops-kaf` must use this shape (without the leading space):

```fish
function sops-kaf
    test (count $argv) -eq 1; or return 2
    test -f "$argv[1]"; or begin; echo "file does not exist: $argv[1]" >&2; return 1; end
    sops -d "$argv[1]" | kubectl apply -f -
end
```

Implement `kubemerge` and `talosmerge` by collecting matching YAML paths, joining them with `:`, and running the same `KUBECONFIG=... kubectl config view --flatten` or `TALOSCONFIG=... talosctl config view` behavior. Preserve `kubectl → kubecolor` as a Fish alias and add `k`, `ka`, `kaf`, and other existing Nu K8s abbreviations.

Implement Zellij helpers with exact names listed above. `zellij-create-or-attach SESSION [--layout PATH]` must attach an existing named session; otherwise start `zellij --layout PATH` when that path exists or `zellij -s SESSION` when it does not. `zellij-murder-all-sessions` must call kill then delete in that order and stop if killing fails.

- [ ] **Step 4: Add completion declarations**

Create `configs/fish/completions/zellij-create-or-attach.fish`:

```fish
complete -c zellij-create-or-attach -l layout -r -F
```

Create `configs/fish/completions/sops-kaf.fish`:

```fish
complete -c sops-kaf -F
```

- [ ] **Step 5: Run tests and parser checks**

Run:

```sh
fish --no-config tests/fish/k8s-zellij.test.fish
for file in configs/fish/functions/{kubemerge,talosmerge,sops-kaf,k8s-base64,zellij-*}.fish configs/fish/completions/{sops-kaf,k8s-base64,zellij-create-or-attach}.fish; do fish --no-execute "$file"; done
```

Expected: helper behavior passes under stubs; every touched Fish file parses.

- [ ] **Step 6: Commit the Kubernetes and Zellij port**

```sh
git add configs/fish/functions configs/fish/completions configs/fish/ez/misc.fish tests/fish/k8s-zellij.test.fish
git commit -m "feat: port Fish Kubernetes and Zellij helpers"
```

### Task 5: Port 1Password and SOPS helpers without secret disclosure

**Files:**
- Create: `configs/fish/functions/{__op-select-ssh-key,op-ssh-public-key,sops-age-public-key,sops-age-private-key,sops-age-private-from-ssh,sops-setup-new-host}.fish`
- Create: `configs/fish/completions/sops-setup-new-host.fish`
- Create: `tests/fish/op-sops.test.fish`
- Modify: `configs/fish/ez/misc.fish`

**Interfaces:**
- Consumes: `op item list --categories 'SSH Key' --format json`, `jq`, `fzf`, and `nix run nixpkgs#ssh-to-age`.
- Produces:
  - `op-ssh-public-key [ITEM_ID]` → public SSH key on stdout.
  - `sops-age-public-key [ITEM_ID]` → public age key on stdout.
  - `sops-age-private-key [ITEM_ID]` → private age key on stdout only as the final pipeline output.
  - `sops-age-private-from-ssh` → converts private SSH key material from stdin.
  - `sops-setup-new-host [--yes] [ITEM_ID]` → writes the local SOPS age key only after confirmation or `--yes`.

- [ ] **Step 1: Write the isolated secret-flow test**

Create `tests/fish/op-sops.test.fish`. It creates a temporary `bin` prepended to `PATH` with stubs:

```fish
# op: list emits a stable JSON SSH-key item; get emits PUBLIC or PRIVATE.
# fzf: returns its stdin unchanged.
# nix: prefixes its stdin with converted:.
```

The test must assert all of these contracts:

```fish
op-ssh-public-key item-1 | string match -q PUBLIC
sops-age-public-key item-1 | string match -q converted:PUBLIC
sops-age-private-key item-1 | string match -q converted:PRIVATE
not string match -q '*PRIVATE*' -- (sops-setup-new-host --yes item-1 2>&1)
```

Run `sops-setup-new-host --yes item-1` with `HOME` pointing to a temporary directory. Assert that the key file contains `converted:PRIVATE`, its mode is `600`, and its parent directory mode is `700`. Also assert that omitting `--yes` and responding `n` leaves no key file.

- [ ] **Step 2: Run the test to verify the functions are absent**

Run: `fish --no-config tests/fish/op-sops.test.fish`

Expected: command-not-found failure for `op-ssh-public-key`.

- [ ] **Step 3: Implement deterministic key selection and public conversion**

Create `__op-select-ssh-key` using JSON instead of the Nu module’s whitespace-column parsing:

```fish
function __op-select-ssh-key
    if test (count $argv) -gt 0
        printf '%s\n' "$argv[1]"
        return
    end

    set -l selected (op item list --categories 'SSH Key' --format json \
        | jq -r '.[] | [.id, .title, .vault.name] | @tsv' \
        | fzf --delimiter=\t --with-nth=2,3)
    test -n "$selected"; or return 1
    string split \t -- "$selected" | head -n 1
end
```

Implement `op-ssh-public-key` as:

```fish
function op-ssh-public-key
    set -l item_id (__op-select-ssh-key $argv)
    or return
    op item get "$item_id" --fields 'label=public key'
end
```

Implement `sops-age-public-key` by selecting once then streaming `op item get "$item_id" --fields 'label=public key'` into `nix run nixpkgs#ssh-to-age`.

- [ ] **Step 4: Implement private conversion and provisioning as streaming operations**

` sops-age-private-key` (without the leading space) must select an ID and stream directly; it must not assign private content to a Fish variable:

```fish
function sops-age-private-key
    set -l item_id (__op-select-ssh-key $argv)
    or return
    op item get "$item_id" --fields 'label=private key' --reveal \
        | nix run nixpkgs#ssh-to-age -- -private-key
end
```

`sops-age-private-from-ssh` reads its standard input and streams it to the same conversion command. `sops-setup-new-host` uses `argparse -n sops-setup-new-host y/yes -- $argv`, selects the key once, asks `read --local --prompt-str 'Write private age key to …? (y/N): '` unless `--yes` is present, runs `mkdir -p -m 700 "$HOME/.config/sops/age"`, sets `umask 077`, then streams the revealed key through `ssh-to-age` into `keys.txt` and runs `chmod 600` on the file. It must not calculate or print a public or private age key merely for logging.

Add only safe abbreviations in `configs/fish/ez/misc.fish`, such as `skaf → sops-kaf`; do not create an abbreviation that expands to a private-key retrieval command.

- [ ] **Step 5: Add the `--yes` completion and run tests**

Create `configs/fish/completions/sops-setup-new-host.fish`:

```fish
complete -c sops-setup-new-host -s y -l yes -d 'Write without prompting'
```

Run:

```sh
fish --no-config tests/fish/op-sops.test.fish
for file in configs/fish/functions/{__op-select-ssh-key,op-ssh-public-key,sops-age-public-key,sops-age-private-key,sops-age-private-from-ssh,sops-setup-new-host}.fish configs/fish/completions/sops-setup-new-host.fish; do fish --no-execute "$file"; done
```

Expected: public and private conversions are correct under stubs, the private value is absent from setup output, and permissions are exactly `700`/`600`.

- [ ] **Step 6: Commit the secure 1Password/SOPS port**

```sh
git add configs/fish/functions configs/fish/completions configs/fish/ez/misc.fish tests/fish/op-sops.test.fish
git commit -m "feat: port secure Fish SOPS helpers"
```

### Task 6: Port project and game helpers; finish the command inventory

**Files:**
- Create: `configs/fish/functions/{eve-pfx,eve-settings,eve-pi-templates,eve-gits,eve-eanm,eve-custom-ship-labeler,eve-pi-template-name,pz-copy-mod-config,pz-mods,stalker2-pfx,stalker2-cd,stalker2-mods,starcitizen-wine-path,starcitizen-controller-settings}.fish`
- Modify: `configs/fish/exports.fish`
- Modify: `docs/superpowers/specs/2026-07-16-fish-migration-design.md`
- Test: `tests/fish/project-helpers-load.test.fish`

**Interfaces:**
- Consumes: `$HOME`, platform detection through `uname`, `scp`, Steam paths, and existing game executables.
- Produces: dashed Fish equivalents for every command sourced by `configs/nu/{eve,pz,stalker2,starcitizen}.nu`.

- [ ] **Step 1: Write the project helper inventory/load test**

Create `tests/fish/project-helpers-load.test.fish` and assert these functions exist after sourcing the Fish configuration:

```fish
for name in eve-pfx eve-settings eve-pi-templates eve-gits eve-eanm eve-custom-ship-labeler eve-pi-template-name pz-copy-mod-config pz-mods stalker2-pfx stalker2-cd stalker2-mods starcitizen-wine-path starcitizen-controller-settings
    functions --query $name; or exit 1
end
```

- [ ] **Step 2: Run the test to verify current missing commands**

Run: `fish --no-config tests/fish/project-helpers-load.test.fish`

Expected: failure on the first missing Nu-equivalent function.

- [ ] **Step 3: Implement platform-aware equivalents**

Compute game paths inside each function or through non-secret private helpers; do not make them universal variables. Preserve behavior exactly:

- `eve-pfx` rejects non-Linux before changing directory.
- `eve-settings`, `eve-pi-templates`, and `eve-gits` change to the same OS-specific directories as Nu.
- `eve-eanm` strips `.local` from `hostname`, changes into the matching settings directory, then runs the existing Zulu/JAR command.
- `eve-pi-template-name` consumes JSON through `jq -r '.Cmt | gsub(" "; "")'`.
- `pz-copy-mod-config [HOST]` defaults to `jezrien`, rejects the current host prefix, and calls `scp` separately for `saved_outfits.txt` and `pz_modlist_settings.cfg`; no `eval` and no `fish -c`.
- `pz-mods`, `stalker2-pfx`, `stalker2-cd`, and `stalker2-mods` use the same Steam roots as Nu.
- The two Star Citizen helpers only print the current guidance text; do not restore obsolete commands.

- [ ] **Step 4: Add the migration matrix to the approved specification**

Append a table to `docs/superpowers/specs/2026-07-16-fish-migration-design.md` listing every function, alias, and abbreviation sourced by `configs/nu/config.nu`; record its exact Fish command or `Intentionally Nu-only`. The expected final state has no `Intentionally Nu-only` entry unless the user explicitly approves one.

- [ ] **Step 5: Run load and parser checks**

Run:

```sh
fish --no-config tests/fish/project-helpers-load.test.fish
for file in configs/fish/functions/{eve-*,pz-*,stalker2-*,starcitizen-*}.fish; do fish --no-execute "$file"; done
```

Expected: all project helpers load and all touched Fish files parse.

- [ ] **Step 6: Commit the project helper port and inventory**

```sh
git add configs/fish/functions configs/fish/exports.fish docs/superpowers/specs/2026-07-16-fish-migration-design.md tests/fish/project-helpers-load.test.fish
git commit -m "feat: complete Fish helper migration"
```

### Task 7: Execute the interactive Fish trial and perform the cutover

**Files:**
- Modify: active host/profile configuration that set `ryk.enableFishTrial = true`
- Modify: `modules/shell/default-shell.nix:11-17` only if removing the completed trial option
- Modify: `modules/shell/fish.nix:5`
- Modify: `docs/superpowers/specs/2026-07-16-fish-migration-design.md`
- Test: manual interactive checks plus Fish parser/test suite

**Interfaces:**
- Consumes: completed Tasks 1–6.
- Produces: `ryk.defaultShell = "fish"`; Fish is login/default shell and Herdr’s configured default shell.

- [ ] **Step 1: Run the complete deterministic test suite before interactive checks**

Run:

```sh
for test in tests/fish/*.test.fish; do fish --no-config "$test"; done
nix flake check --no-build
```

Expected: every Fish test exits zero and Nix evaluation succeeds.

- [ ] **Step 2: Rebuild the trial configuration and test real completion**

Rebuild using the repository’s normal host deployment command. Start a new Fish shell and manually verify:

```fish
herdr <TAB>
kubecolor <TAB>
flux <TAB>
sops-setup-new-host --<TAB>
zellij-create-or-attach --<TAB>
```

Expected: Herdr presents generated command/flag suggestions; Kubecolor and Flux retain Carapace completions; custom helper flags and paths complete. Then run `sops-setup-new-host` interactively with a real SSH key, confirm it writes only after `y`, and inspect the result with `stat -c '%a %n' ~/.config/sops/age ~/.config/sops/age/keys.txt`.

- [ ] **Step 3: Flip the configured default shell after every acceptance criterion passes**

Replace the active host/profile setting with:

```nix
ryk.defaultShell = "fish";
```

Remove `ryk.enableFishTrial`, remove the trial option declaration from `modules/shell/default-shell.nix`, and simplify the Fish module guard back to:

```nix
lib.mkIf (config.ryk.defaultShell == "fish") {
```

Do not delete `configs/nu` in this task; retained version-controlled Nu configuration is the historical source until a later, explicit cleanup request.

- [ ] **Step 4: Rebuild, start a fresh login shell, and verify Herdr configuration**

Run the normal host rebuild, open a fresh login shell, and verify:

```sh
ps -p $$ -o comm=
herdr --default-config | grep -F 'default_shell = "fish"'
fish --no-config -c 'source ~/.dotfiles/configs/fish/config.fish; functions --query sops-age-private-key'
```

Expected: login shell is Fish; Herdr reports Fish as default shell; the secure SOPS helper loads.

- [ ] **Step 5: Update final acceptance evidence and commit**

Record the completed migration matrix and verification commands/results in the design specification. Then commit:

```sh
git add modules/shell/default-shell.nix modules/shell/fish.nix docs/superpowers/specs/2026-07-16-fish-migration-design.md
git commit -m "feat: switch default shell to Fish"
```
