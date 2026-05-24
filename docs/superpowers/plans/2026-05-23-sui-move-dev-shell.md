# Sui/Move Dev Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a Nix-native Sui/Move development environment on jezrien for EVE Frontier modding — custom `sui` and `move-analyzer` packages, a `nix develop` shell with JS tooling, and an opt-in home-manager module that wires helix LSP + tree-sitter highlighting for `.move` files.

**Architecture:** Two custom derivations in `pkgs/` (prebuilt sui CLI tarball patched via `autoPatchelfHook`; move-analyzer built from sui repo source). Both are auto-exposed via `pkgs/default.nix` and the existing `additions` overlay. A new `shells/default.nix` entry pulls them with bun/nodejs/git-lfs. A new `modules/dev/sui.nix` declares `flake.modules.homeManager.sui` (auto-discovered by `import-tree ./modules`) that, when imported by a host and helix is enabled, extends helix with Move LSP + grammar + queries. Version is a single constant in `pkgs/default.nix` passed via `callPackage` and re-read by the module through `pkgs.sui.version`.

**Tech Stack:** Nix flakes, flake-parts, home-manager (as NixOS module), helix editor, Rust (for move-analyzer build), Sui CLI, Move language, tree-sitter.

**Spec reference:** `docs/superpowers/specs/2026-05-23-sui-move-dev-shell-design.md`

---

## File Structure

```
pkgs/
  sui.nix              # NEW — stdenv.mkDerivation, prebuilt sui CLI, autoPatchelfHook
  move-analyzer.nix    # NEW — rustPlatform.buildRustPackage from sui repo source
  default.nix          # MODIFY — add suiVersion let-binding + two callPackage entries

shells/
  default.nix          # MODIFY — add `sui` attribute

configs/
  helix-move/
    queries/           # NEW — vendored highlights.scm, indents.scm, etc.

modules/dev/
  sui.nix              # NEW — flake.modules.homeManager.sui, conditionally extends helix

modules/hosts/jezrien/
  default.nix          # MODIFY — add `sui` to home-manager imports list
```

**Responsibility split (one purpose per file):**

- `pkgs/sui.nix` owns the prebuilt-binary derivation and platform constraint (`x86_64-linux` only)
- `pkgs/move-analyzer.nix` owns the source build derivation
- `pkgs/default.nix` owns the version constant and wires both via `callPackage`
- `shells/default.nix` owns dev shell composition
- `configs/helix-move/queries/` owns vendored tree-sitter queries (may need helix-specific edits)
- `modules/dev/sui.nix` owns helix integration (LSP + grammar + queries install)
- `modules/hosts/jezrien/default.nix` owns the per-host opt-in

---

## Pre-flight: pick the version

The plan uses placeholder `<SUI_VERSION>` throughout. Before Task 1, pick a concrete testnet release tag.

- [ ] **Step 0.1: Browse releases**

Run: `gh release list --repo MystenLabs/sui --limit 30 | grep testnet`
Expected: lines like `Sui testnet-v1.50.1  testnet-v1.50.1  Latest  2026-...`

- [ ] **Step 0.2: Pick a release**

Pick the most recent stable `testnet-v*` release. Record it in this plan as `<SUI_VERSION>` (e.g. `1.50.1`) — every subsequent task that says `<SUI_VERSION>` uses this value. From here on, **replace `<SUI_VERSION>` with the chosen value in commands and file contents.**

- [ ] **Step 0.3: Confirm the prebuilt asset exists**

Run: `gh release view testnet-v<SUI_VERSION> --repo MystenLabs/sui --json assets --jq '.assets[].name' | grep ubuntu-x86_64`
Expected: `sui-testnet-v<SUI_VERSION>-ubuntu-x86_64.tgz`

If the ubuntu-x86_64 asset doesn't exist for the chosen version, pick a different version.

---

## Task 1: Create `pkgs/sui.nix` derivation skeleton

**Files:**
- Create: `pkgs/sui.nix`

- [ ] **Step 1.1: Write the derivation with a sentinel hash**

Create `pkgs/sui.nix` with this exact content:

```nix
{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  version,
}:
stdenv.mkDerivation {
  pname = "sui";
  inherit version;

  src = fetchurl {
    url = "https://github.com/MystenLabs/sui/releases/download/testnet-v${version}/sui-testnet-v${version}-ubuntu-x86_64.tgz";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    openssl
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 sui $out/bin/sui
    runHook postInstall
  '';

  meta = {
    description = "Sui blockchain CLI (prebuilt from MystenLabs releases)";
    homepage = "https://github.com/MystenLabs/sui";
    platforms = [ "x86_64-linux" ];
  };
}
```

- [ ] **Step 1.2: Wire into `pkgs/default.nix`**

Edit `pkgs/default.nix`. Add a `let` block with the version constant and add `sui` to the returned attribute set.

Before:
```nix
{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  ### gaming
  # star citizen
  opentrack = pkgs.callPackage ./opentrack.nix { };
  opentrack-StarCitizen = pkgs.callPackage ./opentrack-StarCitizen.nix { };
  # misc
  jackify = pkgs.callPackage ./jackify.nix { };
  eve-wrench = pkgs.callPackage ./eve-wrench.nix { };
  rift-intel-tool = pkgs.callPackage ./rift-intel-tool.nix { };

  ### misc
  rackpeek = pkgs.callPackage ./rackpeek.nix { };
  tpm = pkgs.callPackage ./tpm.nix { };
}
```

After:
```nix
{
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  suiVersion = "<SUI_VERSION>";
in
{
  ### gaming
  # star citizen
  opentrack = pkgs.callPackage ./opentrack.nix { };
  opentrack-StarCitizen = pkgs.callPackage ./opentrack-StarCitizen.nix { };
  # misc
  jackify = pkgs.callPackage ./jackify.nix { };
  eve-wrench = pkgs.callPackage ./eve-wrench.nix { };
  rift-intel-tool = pkgs.callPackage ./rift-intel-tool.nix { };

  ### misc
  rackpeek = pkgs.callPackage ./rackpeek.nix { };
  tpm = pkgs.callPackage ./tpm.nix { };

  ### sui/move (eve frontier)
  sui = pkgs.callPackage ./sui.nix { version = suiVersion; };
}
```

- [ ] **Step 1.3: Build to discover the real hash (test that fails as expected)**

Run: `nix build .#sui --no-link 2>&1 | tee /tmp/sui-hash.log`

Expected: build fails with a hash mismatch like:
```
error: hash mismatch in fixed-output derivation '...sui-...':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-<REAL_HASH>=
```

- [ ] **Step 1.4: Update the sha256 with the real hash**

Extract the `got:` hash from `/tmp/sui-hash.log`. Replace the all-zeros placeholder in `pkgs/sui.nix` with the real hash.

- [ ] **Step 1.5: Build to verify it now succeeds**

Run: `nix build .#sui --no-link`
Expected: silent success (exit 0).

- [ ] **Step 1.6: Verify the binary runs**

Run: `nix run .#sui -- --version`
Expected: prints something like `sui 1.50.1-<git-hash>`. If `autoPatchelfHook` missed a library, you'll get a `cannot find lib*.so` error — add that library to `buildInputs` (most commonly `glibc`, `libgcc`, or `zlib` — use `ldd $(nix path-info .#sui)/bin/sui` to see). Re-run from Step 1.5.

- [ ] **Step 1.7: Commit**

```bash
git add pkgs/sui.nix pkgs/default.nix
git commit -m "$(cat <<'EOF'
feat(pkgs): add sui CLI derivation

Prebuilt MystenLabs release tarball, patched via autoPatchelfHook.
Pinned to testnet-v<SUI_VERSION>. Installs only the sui binary
(skips sui-node, sui-bridge, etc.) to keep closure small.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Create `pkgs/move-analyzer.nix` derivation

**Files:**
- Create: `pkgs/move-analyzer.nix`
- Modify: `pkgs/default.nix`

- [ ] **Step 2.1: Write the derivation with sentinel hashes**

Create `pkgs/move-analyzer.nix`:

```nix
{
  rustPlatform,
  fetchFromGitHub,
  version,
}:
rustPlatform.buildRustPackage {
  pname = "move-analyzer";
  inherit version;

  src = fetchFromGitHub {
    owner = "MystenLabs";
    repo = "sui";
    rev = "testnet-v${version}";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  buildAndTestSubdir = "external-crates/move/crates/move-analyzer";

  doCheck = false;

  meta = {
    description = "Move language server (from MystenLabs/sui)";
    homepage = "https://github.com/MystenLabs/sui";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
```

**Note on `cargoLock.lockFile = "${src}/Cargo.lock"`:** if Nix complains that `src` is not in scope inside `cargoLock`, restructure as a let-binding:

```nix
let
  src = fetchFromGitHub { ... };
in
rustPlatform.buildRustPackage {
  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";
  ...
}
```

- [ ] **Step 2.2: Wire into `pkgs/default.nix`**

Add a line after the `sui` entry:

```nix
  move-analyzer = pkgs.callPackage ./move-analyzer.nix { version = suiVersion; };
```

- [ ] **Step 2.3: Build to discover the source hash**

Run: `nix build .#move-analyzer --no-link 2>&1 | tee /tmp/move-analyzer-hash.log`
Expected: hash mismatch error with a real `got:` hash for the fetchFromGitHub.

- [ ] **Step 2.4: Update the src sha256**

Replace the placeholder in `pkgs/move-analyzer.nix` with the real hash.

- [ ] **Step 2.5: Build again — handle cargo deps**

Run: `nix build .#move-analyzer --no-link 2>&1 | tee /tmp/move-analyzer-build.log`

Three possible outcomes:
1. **Success** — proceed to Step 2.7.
2. **`cargoLock` missing `outputHashes` for git dependencies** — error mentions specific git deps (e.g., `error: No hash was found for git dependency 'foo'`). Add `cargoLock.outputHashes = { "<crate>-<version>" = "<hash>"; };` to the derivation. Re-run; iterate hash by hash.
3. **Compilation failure inside the move-analyzer crate** — likely a missing system dep. Common candidates: `pkg-config`, `openssl`, `libgit2`. Add to `nativeBuildInputs` or `buildInputs`. Re-run.

- [ ] **Step 2.6: Verify the binary runs**

Run: `nix run .#move-analyzer -- --version 2>&1 || nix run .#move-analyzer -- --help 2>&1 | head -5`

Expected: prints version OR help text (move-analyzer may not have `--version`; help text is acceptable confirmation it runs).

- [ ] **Step 2.7: Commit**

```bash
git add pkgs/move-analyzer.nix pkgs/default.nix
git commit -m "$(cat <<'EOF'
feat(pkgs): add move-analyzer LSP from sui source

Built via rustPlatform.buildRustPackage from MystenLabs/sui at the
same testnet tag as the sui CLI. Tests disabled (require broader
workspace context).

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add the `sui` dev shell

**Files:**
- Modify: `shells/default.nix`

- [ ] **Step 3.1: Add the `sui` attribute**

Edit `shells/default.nix`. Insert before the closing `}`:

```nix
  sui = pkgs.mkShell {
    buildInputs = with pkgs; [
      sui
      move-analyzer
      bun
      nodejs
      git-lfs
    ];

    shellHook = ''
      echo "sui $(${pkgs.sui}/bin/sui --version 2>/dev/null | head -1)"
      echo "network: $(${pkgs.sui}/bin/sui client active-env 2>/dev/null || echo 'not configured')"
      echo ""
      echo "  faucet:    sui client faucet"
      echo "  localnet:  sui start --with-faucet"
      echo "  build:     sui move build"
      exec nu
    '';
  };
```

- [ ] **Step 3.2: Verify the shell evaluates**

Run: `nix flake check 2>&1 | tail -20`
Expected: no errors (warnings ok).

- [ ] **Step 3.3: Verify the shell launches and tools are present**

Run:
```bash
nix develop .#sui --command bash -c 'sui --version && move-analyzer --version 2>/dev/null || move-analyzer --help | head -1; bun --version; node --version; git lfs version'
```
Expected: all five commands print their version/help output.

- [ ] **Step 3.4: Commit**

```bash
git add shells/default.nix
git commit -m "$(cat <<'EOF'
feat(shells): add sui dev shell for eve frontier modding

sui CLI + move-analyzer LSP + bun (preferred) + nodejs (fallback)
+ git-lfs. shellHook prints quick reference and execs into nu for
consistency with other shells.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Vendor tree-sitter-move queries

**Files:**
- Create: `configs/helix-move/queries/highlights.scm`
- Create: `configs/helix-move/queries/indents.scm` (if upstream has it)
- Create: `configs/helix-move/queries/injections.scm` (if upstream has it)
- Create: `configs/helix-move/queries/locals.scm` (if upstream has it)

- [ ] **Step 4.1: Fetch upstream queries**

Run from `/tmp`:
```bash
cd /tmp
rm -rf sui-clone
git clone --depth 1 --branch testnet-v<SUI_VERSION> https://github.com/MystenLabs/sui.git sui-clone
ls sui-clone/external-crates/move/tooling/tree-sitter-move/queries/
```
Expected: lists `.scm` files (typically `highlights.scm`, possibly `indents.scm`, `injections.scm`, `locals.scm`).

- [ ] **Step 4.2: Copy queries into the repo**

Run from the dotfiles repo:
```bash
mkdir -p configs/helix-move/queries
cp /tmp/sui-clone/external-crates/move/tooling/tree-sitter-move/queries/*.scm configs/helix-move/queries/
ls configs/helix-move/queries/
```
Expected: same file list as Step 4.1 now in `configs/helix-move/queries/`.

- [ ] **Step 4.3: Commit**

```bash
git add configs/helix-move/queries/
git commit -m "$(cat <<'EOF'
feat(configs): vendor tree-sitter-move queries

Copied verbatim from MystenLabs/sui at testnet-v<SUI_VERSION>.
Owned in-repo so helix-specific tweaks live here, not upstream.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Create the `sui` home-manager module

**Files:**
- Create: `modules/dev/sui.nix`

- [ ] **Step 5.1: Write the module**

Create `modules/dev/sui.nix`:

```nix
{ ... }:
{
  flake.modules.homeManager.sui =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      programs.helix = lib.mkIf config.programs.helix.enable {
        languages = {
          language-server.move-analyzer = {
            command = lib.getExe pkgs.move-analyzer;
          };

          grammar = [
            {
              name = "move";
              source = {
                git = "https://github.com/MystenLabs/sui.git";
                rev = "testnet-v${pkgs.sui.version}";
                subpath = "external-crates/move/tooling/tree-sitter-move";
              };
            }
          ];

          language = [
            {
              name = "move";
              scope = "source.move";
              file-types = [ "move" ];
              language-servers = [ "move-analyzer" ];
              auto-format = false;
              indent = {
                tab-width = 4;
                unit = "    ";
              };
            }
          ];
        };
      };

      home.file.".config/helix/runtime/queries/move" = lib.mkIf config.programs.helix.enable {
        source = ../../configs/helix-move/queries;
        recursive = true;
      };
    };
}
```

- [ ] **Step 5.2: Verify the flake still evaluates**

Run: `nix flake check 2>&1 | tail -20`
Expected: no errors. The module is now registered as `flake.modules.homeManager.sui` but no host imports it yet, so it's inert.

**If `programs.helix.languages.grammar` is rejected** as not a valid option: home-manager's helix module may not accept `grammar` directly. Workaround: replace the `grammar = [...]` block with `xdg.configFile."helix/languages.toml.d/move-grammar.toml".text = ''[[grammar]]...'';` and rely on helix merging — or skip the grammar declaration entirely and run `hx --grammar fetch && hx --grammar build` manually after Step 6.4. Document whichever path you take in the commit message.

- [ ] **Step 5.3: Commit**

```bash
git add modules/dev/sui.nix
git commit -m "$(cat <<'EOF'
feat(modules/dev): add sui home-manager module

Conditionally extends helix with move-analyzer LSP, tree-sitter-move
grammar pinned to the same sui release, and vendored query files.
Opt-in by importing in a host or role. Inert when helix is disabled.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Wire `sui` into jezrien's home-manager imports

**Files:**
- Modify: `modules/hosts/jezrien/default.nix`

- [ ] **Step 6.1: Add `sui` to the imports list**

In `modules/hosts/jezrien/default.nix`, find the `imports = with hmModules; [ ... ];` block inside the `users.${username}` config. Add `sui` alphabetically among the individual modules:

Locate this section (around line ~58):
```nix
              imports = with hmModules; [
                # groups
                developer
                gaming
                _3dp

                # individual modules
                btop
                ai-common
                claude-code
                # hermes-agent
                codex
                espanso
                eve-online
                easyeffects
                homelab
                jackify
                keebs
                nushell
                opencode
                # sesh
                sops
                starsector
                swappy
                television
                wezterm
                zen-browser
              ];
```

Add `sui` between `starsector` and `swappy`:
```nix
                starsector
                sui
                swappy
```

- [ ] **Step 6.2: Dry-evaluate the host**

Run: `nix flake check 2>&1 | tail -30`
Expected: no eval errors.

- [ ] **Step 6.3: Dry-build the host**

Run: `nixos-rebuild build --flake .#jezrien 2>&1 | tail -30`
Expected: produces a `result` symlink without errors.

- [ ] **Step 6.4: Commit**

```bash
git add modules/hosts/jezrien/default.nix
git commit -m "$(cat <<'EOF'
feat(hosts/jezrien): import sui home-manager module

Enables move-analyzer LSP and tree-sitter highlighting for .move
files in helix on jezrien.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Activate on jezrien & end-to-end verification

**Files:** (no edits unless query tweaks needed)

- [ ] **Step 7.1: Switch into the new configuration**

Run: `sudo nixos-rebuild switch --flake .#jezrien`
Expected: rebuild completes; activation script runs without errors.

- [ ] **Step 7.2: Build helix's grammar bundle**

The grammar source is declared in config but helix doesn't auto-fetch. Run:

```bash
hx --grammar fetch
hx --grammar build
```
Expected: prints `Fetching move...` and `Building move...` (or already up to date).

- [ ] **Step 7.3: Create a hello-world Move project (from inside the dev shell)**

Run:
```bash
cd /tmp
rm -rf sui-hello
nix develop /home/dusty/projects/dotfiles#sui --command bash -c 'sui move new sui-hello && cd sui-hello && ls'
```
Expected: creates `sui-hello/` with `Move.toml` and `sources/sui_hello.move`.

- [ ] **Step 7.4: Compile the project**

```bash
cd /tmp/sui-hello
nix develop /home/dusty/projects/dotfiles#sui --command sui move build
```
Expected: prints `BUILDING sui_hello` and finishes successfully. (May print warnings about missing dependencies on first run; that's fine.)

- [ ] **Step 7.5: Open the Move file in helix and check LSP + highlighting**

```bash
hx /tmp/sui-hello/sources/sui_hello.move
```

Then inside helix:
- Wait 2-3 seconds for LSP to initialize.
- Type `:log-open` and check the log buffer for errors.
- Press `space + d` (or your normal diagnostics binding) to see diagnostics — expect none or trivial ones on the generated template.
- Visually confirm syntax highlighting: keywords (`module`, `public`, `fun`) should be colored, strings/numbers distinguished.

**If LSP is silent:**
- Verify the binary is in PATH inside the home-manager environment: `which move-analyzer`
- Check helix's `:log-open` for "language server move-analyzer not found"
- The home-manager-rendered `languages.toml` lives at `~/.config/helix/languages.toml` — `cat` it and confirm the `[language-server.move-analyzer]` and `[[language]]` blocks are there.

**If highlighting is missing:**
- Confirm `~/.config/helix/runtime/queries/move/highlights.scm` is the symlink installed by home-manager.
- In `:log-open`, look for `Error: Predicate not supported` lines — those identify queries that need helix-specific tweaks.

- [ ] **Step 7.6: Fix any query predicate errors (if needed)**

If `:log-open` shows query errors like `Predicate '#any-of?' not supported`:

Edit `configs/helix-move/queries/highlights.scm` (or whichever query file errored). Common fix: replace `#any-of?` with `#match?` using a regex alternation:

Before:
```scheme
((identifier) @keyword (#any-of? @keyword "module" "public" "fun"))
```

After:
```scheme
((identifier) @keyword (#match? @keyword "^(module|public|fun)$"))
```

After each fix, run `home-manager switch` (or `sudo nixos-rebuild switch --flake .#jezrien`) to redeploy the queries, then reopen the file in helix.

When all errors are gone:
```bash
git add configs/helix-move/queries/
git commit -m "$(cat <<'EOF'
fix(configs/helix-move): adapt queries for helix predicates

Rewrote upstream predicates not supported by helix's tree-sitter
implementation. Verified clean :log-open on a generated sui move
project.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

If no fixes were needed, skip the commit.

- [ ] **Step 7.7: Final sanity check**

Run: `nix flake check`
Expected: clean.

Run: `git status`
Expected: working tree clean (all changes committed).

Run: `git log --oneline -10`
Expected: see the 6-7 task commits in order.

---

## Success Criteria Verification

Check each criterion from the spec:

- [ ] `nix flake check` passes (verified in Step 7.7)
- [ ] `nix develop /home/dusty/projects/dotfiles#sui` drops into nushell with the quick-ref printed (verified in Step 3.3, expanded in Step 7.3)
- [ ] `sui --version` and `move-analyzer --version`/`--help` succeed inside the shell (verified in Step 3.3)
- [ ] On jezrien, a `.move` file in helix shows LSP diagnostics and syntax highlighting with no errors in `:log-open` (verified in Step 7.5 / 7.6)
- [ ] `sui move new hello && cd hello && sui move build` compiles a hello-world (verified in Steps 7.3–7.4)

---

## Notes for the implementer

- **Version bumps later:** edit `suiVersion` in `pkgs/default.nix` (one place), then re-run `nix build .#sui` and `nix build .#move-analyzer` — both will fail with new `got:` hashes, paste them in. The home-manager module reads `pkgs.sui.version` so it follows automatically. Helix will refetch the tree-sitter source on its own.
- **macOS:** out of scope. The `meta.platforms` constraint on `pkgs/sui.nix` ensures `nix flake check` skips it on darwin.
- **Don't edit `modules/dev/helix.nix`** — the design constraint is that helix stays domain-agnostic. All Move-specific helix config lives in `modules/dev/sui.nix`.
- **Reachable from outside dotfiles:** once shipped, you can use the shell from your EF project directory via `nix develop /home/dusty/projects/dotfiles#sui` or by adding a thin `flake.nix` to that project that references this flake.
