# Sui/Move Dev Shell — Design

**Date:** 2026-05-23
**Purpose:** Enable Sui blockchain / Move language development for EVE Frontier modding on jezrien, with first-class Nix integration and helix LSP + syntax highlighting.

## Background

EVE Frontier modding requires the Sui CLI (Move compilation, deploy, network ops) and benefits from `move-analyzer` (LSP) plus a tree-sitter grammar for syntax highlighting in helix. Neither `sui` nor `move-analyzer` is packaged in nixpkgs. The upstream installer (`suiup`) drops dynamically-linked binaries that won't run on NixOS without patching. Docker works but degrades editor DX.

This spec packages both tools as Nix derivations and exposes them through the existing overlay/shell/module pattern in this flake.

## Scope

In-scope:
- Custom Nix derivations for `sui` CLI (prebuilt) and `move-analyzer` (built from source)
- A `sui` dev shell pulling those plus `bun`, `nodejs`, `git-lfs`
- A home-manager module extending helix with Move LSP + tree-sitter grammar + queries
- Vendored Move queries in `configs/helix-move/queries/`
- Pinning the sui CLI, move-analyzer, and tree-sitter grammar to the same Mysten release tag

Out-of-scope:
- macOS support for `sui` (Linux-only — `taln` host gets nothing)
- Auto-starting localnet
- Bundling EVE Frontier project templates / scaffolds
- Editing `modules/dev/helix.nix` (helix module stays domain-agnostic)

## Architecture

### File layout

```
pkgs/
  sui.nix              # NEW — prebuilt CLI derivation
  move-analyzer.nix    # NEW — built from sui repo source

overlays/
  default.nix          # EDIT — expose both via `additions`

shells/
  default.nix          # EDIT — add `sui` shell entry

modules/dev/
  sui.nix              # NEW — flake.modules.homeManager.sui

configs/
  helix-move/
    queries/           # NEW — vendored tree-sitter-move queries (highlights.scm, etc.)

hosts/jezrien/
  home.nix (or role)   # EDIT — import the new module
```

### Pinning strategy

A single version string (e.g. `"1.50.1"`) shared across `pkgs/sui.nix`, `pkgs/move-analyzer.nix`, and the tree-sitter grammar `rev` in `modules/dev/sui.nix`. Bumping = update one constant + three hashes. Channel: `testnet` (matches EVE Frontier docs).

## Component design

### `pkgs/sui.nix` — prebuilt CLI

```nix
{ stdenv, fetchurl, autoPatchelfHook, openssl, ... }:
stdenv.mkDerivation {
  pname = "sui";
  version = "<pinned>";
  src = fetchurl {
    url = "https://github.com/MystenLabs/sui/releases/download/testnet-v${version}/sui-testnet-v${version}-ubuntu-x86_64.tgz";
    sha256 = "<pinned>";
  };
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib openssl ];   # adjust to match `ldd ./sui` output
  sourceRoot = ".";
  installPhase = ''
    runHook preInstall
    install -Dm755 sui $out/bin/sui
    runHook postInstall
  '';
  meta.platforms = [ "x86_64-linux" ];
}
```

Mysten's tarball ships the full toolchain (sui-node, sui-bridge, etc.). We install only `sui` to keep closure size small — Move development doesn't need the others.

### `pkgs/move-analyzer.nix` — built from source

```nix
{ rustPlatform, fetchFromGitHub, ... }:
rustPlatform.buildRustPackage {
  pname = "move-analyzer";
  version = "<pinned, same as sui>";
  src = fetchFromGitHub {
    owner = "MystenLabs"; repo = "sui";
    rev = "testnet-v${version}";
    sha256 = "<pinned>";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";
  buildAndTestSubdir = "external-crates/move/crates/move-analyzer";
  doCheck = false;   # full test suite requires broader sui build context
}
```

First build is slow (Rust + portions of the Move workspace); subsequent builds cache.

### `overlays/default.nix`

Append to existing `additions`:

```nix
sui            = final.callPackage ../pkgs/sui.nix { };
move-analyzer  = final.callPackage ../pkgs/move-analyzer.nix { };
```

### `shells/default.nix`

New attribute alongside `default`, `react`, `rust`, `sptarkov-server`:

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

Usable from any directory: `nix develop /home/dusty/projects/dotfiles#sui`.

### `modules/dev/sui.nix` — opt-in helix extension

Follows the `flake.modules.homeManager.helix` pattern: defines a named module, opt-in by importing it in a host or role. No `mkEnableOption`. Gates helix-related config on `config.programs.helix.enable` so importing it on a host without helix is a no-op.

```nix
{ inputs, ... }:
{
  flake.modules.homeManager.sui =
    { lib, config, pkgs, ... }:
    let suiVersion = "<pinned>"; in
    {
      programs.helix = lib.mkIf config.programs.helix.enable {
        languages = {
          language-server.move-analyzer = {
            command = lib.getExe pkgs.move-analyzer;
          };
          grammar = [{
            name = "move";
            source = {
              git = "https://github.com/MystenLabs/sui.git";
              rev = "testnet-v${suiVersion}";
              subpath = "external-crates/move/tooling/tree-sitter-move";
            };
          }];
          language = [{
            name = "move";
            scope = "source.move";
            file-types = [ "move" ];
            language-servers = [ "move-analyzer" ];
            auto-format = false;
            indent = { tab-width = 4; unit = "    "; };
          }];
        };
      };

      home.file.".config/helix/runtime/queries/move" = lib.mkIf config.programs.helix.enable {
        source = ../../configs/helix-move/queries;
        recursive = true;
      };
    };
}
```

### `configs/helix-move/queries/`

Vendor `highlights.scm`, `indents.scm`, `injections.scm`, `locals.scm` (whichever exist) from `MystenLabs/sui:external-crates/move/tooling/tree-sitter-move/queries/` at the pinned tag. Commit them to this repo so any helix-specific edits are owned here.

**Expected delta from upstream:** the upstream queries target Neovim/nvim-treesitter. Predicates like `#any-of?` may need to be rewritten to `#match?` for helix. Apply edits during implementation, verify against `:log-open` in helix.

### Host wiring

Add `inputs.self.modules.homeManager.sui` (or equivalent — match how `helix` is wired today) to jezrien's home-manager imports. Verify by opening any `.move` file in helix and confirming LSP responds + syntax highlights.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Mysten changes their release tarball naming/layout | Pinned URL — breaks loudly on version bump, easy to fix |
| `autoPatchelfHook` misses a runtime dep | `ldd` the binary during implementation; add missing libs to `buildInputs` |
| `move-analyzer` cargo workspace doesn't build standalone | Fallback: build entire sui workspace, install only move-analyzer bin |
| Upstream tree-sitter queries broken on helix | Vendored — fix in-repo, no upstream coordination needed |
| Bun chokes on a `builder-scaffold` script that hardcodes `node` | `nodejs` is already in the shell as fallback |
| nixpkgs adds `sui` later, causes attr collision in overlay | Use `lib.optionalAttrs (!prev ? sui)` guard if/when this happens; not now |

## Success criteria

1. `nix flake check` passes after all changes
2. `nix develop /home/dusty/projects/dotfiles#sui` drops into nushell with the quick-ref printed
3. Inside the shell, `sui --version` and `move-analyzer --version` both succeed
4. On jezrien, opening a `.move` file in helix shows LSP diagnostics and syntax highlighting (no errors in `:log-open`)
5. `sui move new hello && cd hello && sui move build` compiles a hello-world Move package from inside the shell

## Open implementation questions

- Exact `suiVersion` to pin — pick the latest `testnet-v*` release at implementation time
- Whether `move-analyzer` needs `cargoLock.outputHashes` for git deps — discover empirically
