# OMP Release Updater Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a pinned OMP release update a single explicit `nix run .#update-oh-my-pi` command while preserving reproducible Nix packaging.

**Architecture:** Store the upstream release version, asset names, and SRI hashes in `release.json`; `default.nix` consumes that lock data and retains all binary packaging logic. A Bash updater fetches and validates GitHub release metadata, emits normalized lock JSON atomically, and performs the existing native Nix package build. It is exposed as a runnable flake package and tested through a fixture-driven Bash test executed by a Nix check.

**Tech Stack:** Nix flakes, Home Manager modules, Bash, `curl`, `jq`, GitHub Releases API, `nix hash convert`.

## Global Constraints

- Preserve the standalone upstream-binary packaging model and the Linux ELF interpreter/wrapper behavior.
- Preserve four module targets: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`.
- Obtain release hashes from GitHub Release API asset `digest` fields; normalize them to SRI SHA-256 strings with `nix hash convert --hash-algo sha256 --to sri`.
- Accept only stable releases: reject a draft, prerelease, bad version input, missing expected asset, or absent/malformed SHA-256 digest.
- Remove Nushell-specific OMP completions and delete `_carapace.nix`.
- Generated Fish and Bash completions must remain unchanged in behavior.
- The updater must not deploy a host configuration and must not invoke upstream `omp update`.
- Do not build or emulate a non-native platform binary locally.

---

### Task 1: Separate OMP release lock data from package logic

**Files:**
- Create: `modules/ai/oh-my-pi/release.json`
- Modify: `modules/ai/oh-my-pi/default.nix:1-145`
- Delete: `modules/ai/oh-my-pi/_carapace.nix`

**Interfaces:**
- Consumes: a JSON object containing `version` and a four-entry `sources` map.
- Produces: `mkOhMyPi` obtains `version` and `sources` from `release.json`; no module writes `carapace/specs/omp.yaml`.

- [ ] **Step 1: Create the initial release lock with the current package values**

Create `modules/ai/oh-my-pi/release.json`. Preserve version `16.4.8`, the four current asset names, and convert each existing legacy Nix Base32 hash to SRI syntax. Its exact shape is:

```json
{
  "version": "16.4.8",
  "sources": {
    "x86_64-linux": { "asset": "omp-linux-x64", "hash": "sha256-<converted-current-linux-x64-hash>" },
    "aarch64-linux": { "asset": "omp-linux-arm64", "hash": "sha256-<converted-current-linux-arm64-hash>" },
    "x86_64-darwin": { "asset": "omp-darwin-x64", "hash": "sha256-<converted-current-darwin-x64-hash>" },
    "aarch64-darwin": { "asset": "omp-darwin-arm64", "hash": "sha256-<converted-current-darwin-arm64-hash>" }
  }
}
```

Derive each placeholder once with:

```sh
nix hash convert --hash-algo sha256 --to sri '<existing legacy Base32 hash>'
```

- [ ] **Step 2: Validate the initial lock document**

Run:

```sh
jq -e '
  .version == "16.4.8" and
  ([.sources | keys[]] | sort) ==
  ["aarch64-darwin", "aarch64-linux", "x86_64-darwin", "x86_64-linux"] and
  ([.sources[] | .hash | startswith("sha256-")] | all)
' modules/ai/oh-my-pi/release.json
```

Expected: exit status `0`; the lock retains every current source target in SRI form.

- [ ] **Step 3: Refactor `default.nix` to read the JSON lock**

Replace the top-level inline version and source table with:

```nix
{ ... }:
let
  release = builtins.fromJSON (builtins.readFile ./release.json);
  inherit (release) version sources;

  mkOhMyPi =
```

Inside `mkOhMyPi`, remove its locally declared `sources` attribute set. Keep the existing `srcInfo`, `fetchurl`, Linux wrapper, install check, metadata, and `meta.platforms = builtins.attrNames sources` unchanged. Change each source hash reference to the JSON field name:

```nix
src = pkgs.fetchurl {
  url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${srcInfo.asset}";
  sha256 = srcInfo.hash;
};
```

- [ ] **Step 4: Remove Nushell Carapace integration**

Remove:

```nix
carapace = import ./_carapace.nix;
```

and delete this complete merge branch:

```nix
(lib.mkIf (config.ryk.defaultShell == "nushell") {
  xdg.configFile."carapace/specs/omp.yaml".text = builtins.toJSON carapace.spec;
})
```

Delete `modules/ai/oh-my-pi/_carapace.nix`. Leave Fish and Bash completion branches intact.

- [ ] **Step 5: Verify the refactor and completion behavior**

Run:

```sh
nix build .#oh-my-pi
```

Expected: the OMP package builds successfully and its existing install check runs `omp --version` with a temporary `HOME`. Inspect the module source and confirm its only OMP completion outputs are Fish and Bash; no Nushell branch or Carapace import remains.

- [ ] **Step 6: Commit the focused lock-data refactor**

```sh
git add modules/ai/oh-my-pi/default.nix modules/ai/oh-my-pi/release.json modules/ai/oh-my-pi/_carapace.nix
git commit -m "refactor: separate OMP release lock data"
```

### Task 2: Implement fixture-tested release metadata normalization

**Files:**
- Create: `modules/ai/oh-my-pi/update-omp.sh`
- Create: `modules/ai/oh-my-pi/update-omp.test.sh`

**Interfaces:**
- Consumes: `normalize_release RELEASE_JSON_PATH [REQUESTED_VERSION]` from `update-omp.sh`.
- Produces: a normalized `release.json` object on stdout or a nonzero status with no output file writes.
- Consumed later by `main`, which requests release JSON over HTTPS and passes it to `normalize_release`.

- [ ] **Step 1: Write the failing fixture test**

Create executable `modules/ai/oh-my-pi/update-omp.test.sh`. It must source the updater without executing `main`, create release API fixtures in `mktemp -d`, and assert all of the following:

```bash
#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$module_dir/update-omp.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

write_release() {
  local path="$1" draft="$2" prerelease="$3" omit_asset="${4:-}"
  jq -n \
    --argjson draft "$draft" \
    --argjson prerelease "$prerelease" \
    --arg omitted "$omit_asset" \
    '{tag_name:"v17.0.1", draft:$draft, prerelease:$prerelease,
      assets:[
        {name:"omp-linux-x64", digest:"sha256:427a8743b0b4ef701cc4a0c66bf1f0b91cec06280e8df62294a114e07fb38215"},
        {name:"omp-linux-arm64", digest:"sha256:8ce73061e02f6d4e07dfa14d0f593d0894987056f703b18c1b1518d561eea509"},
        {name:"omp-darwin-x64", digest:"sha256:1631a0ed8e2f734ce867bb44bcdba1fd6dceb35d8ab4c20a137629ebdcd6cb46"},
        {name:"omp-darwin-arm64", digest:"sha256:ef7bffcce5233a5a20a2c77bee17e0a58eee4d86a8cacc5e77d05a3cee954cf8"}
      ] | map(select(.name != $omitted))}' > "$path"
}

write_release "$tmpdir/stable.json" false false
normalize_release "$tmpdir/stable.json" 17.0.1 > "$tmpdir/lock.json"
jq -e '.version == "17.0.1" and .sources["x86_64-linux"].hash == "sha256-QnqHQ7C073AcxKDGa/HwuRzsBigOjfYilKEU4H+zghU="' "$tmpdir/lock.json"

write_release "$tmpdir/draft.json" true false
! normalize_release "$tmpdir/draft.json" 17.0.1
write_release "$tmpdir/pre.json" false true
! normalize_release "$tmpdir/pre.json" 17.0.1
write_release "$tmpdir/missing.json" false false omp-linux-arm64
! normalize_release "$tmpdir/missing.json" 17.0.1
```

Add one malformed-digest fixture by replacing an asset `digest` with `sha512:bad`; assert `normalize_release` returns nonzero.

- [ ] **Step 2: Run the test and confirm the expected initial failure**

Run:

```sh
nix shell nixpkgs#bash nixpkgs#jq --command bash modules/ai/oh-my-pi/update-omp.test.sh
```

Expected: FAIL because `update-omp.sh` and `normalize_release` do not yet exist.

- [ ] **Step 3: Implement only the pure normalization interface**

Create `modules/ai/oh-my-pi/update-omp.sh` with this import-safe structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly api_base='https://api.github.com/repos/can1357/oh-my-pi/releases'
readonly systems=(x86_64-linux aarch64-linux x86_64-darwin aarch64-darwin)
readonly assets=(omp-linux-x64 omp-linux-arm64 omp-darwin-x64 omp-darwin-arm64)

sri_hash() {
  nix hash convert --hash-algo sha256 --to sri "$1"
}

normalize_release() {
  local release_json="$1" requested_version="${2:-}"
  jq -e '
    (.draft | not) and (.prerelease | not) and
    (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
  ' "$release_json" >/dev/null

  local version
  version="$(jq -er '.tag_name | ltrimstr("v")' "$release_json")"
  [[ -z "$requested_version" || "$version" == "$requested_version" ]] || return 1

  local hashes=()
  local asset digest
  for asset in "${assets[@]}"; do
    digest="$(jq -er --arg asset "$asset" '[.assets[] | select(.name == $asset) | .digest] | if length == 1 then .[0] else error("expected exactly one asset") end' "$release_json")"
    [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] || return 1
    hashes+=("$(sri_hash "${digest#sha256:}")")
  done

  jq -n \
    --arg version "$version" \
    --arg linux_x64 "${hashes[0]}" --arg linux_arm64 "${hashes[1]}" \
    --arg darwin_x64 "${hashes[2]}" --arg darwin_arm64 "${hashes[3]}" \
    '{version:$version,sources:{
      "x86_64-linux":{asset:"omp-linux-x64",hash:$linux_x64},
      "aarch64-linux":{asset:"omp-linux-arm64",hash:$linux_arm64},
      "x86_64-darwin":{asset:"omp-darwin-x64",hash:$darwin_x64},
      "aarch64-darwin":{asset:"omp-darwin-arm64",hash:$darwin_arm64}}}'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
```

Implement `main` in the next task. Do not write `release.json` in this task.

- [ ] **Step 4: Run the fixture test and confirm it passes**

Run:

```sh
nix shell nixpkgs#bash nixpkgs#jq nixpkgs#nix --command bash modules/ai/oh-my-pi/update-omp.test.sh
```

Expected: exit status `0`; valid metadata produces exactly the expected version and SRI hash, and all invalid metadata cases are rejected.

- [ ] **Step 5: Commit the parser and its contract test**

```sh
git add modules/ai/oh-my-pi/update-omp.sh modules/ai/oh-my-pi/update-omp.test.sh
git commit -m "feat: validate OMP release metadata"
```

### Task 3: Expose the one-command updater and Nix check

**Files:**
- Modify: `modules/ai/oh-my-pi/update-omp.sh`
- Modify: `modules/ai/oh-my-pi/default.nix:140-145`

**Interfaces:**
- Consumes: `normalize_release` from Task 2 and `modules/ai/oh-my-pi/release.json`.
- Produces: package `packages.update-oh-my-pi`, runnable with `nix run .#update-oh-my-pi [-- VERSION]`; package check `checks.oh-my-pi-update`.

- [ ] **Step 1: Extend the test with atomic write behavior**

Add assertions that `write_lock SOURCE DESTINATION` writes a valid replacement via a temporary sibling file and that an invalid release never changes a preexisting destination:

```bash
printf '%s\n' '{"sentinel":true}' > "$tmpdir/existing.json"
! normalize_release "$tmpdir/draft.json" 17.0.1 > "$tmpdir/new.json"
jq -e '.sentinel == true' "$tmpdir/existing.json"
write_lock "$tmpdir/lock.json" "$tmpdir/existing.json"
jq -e '.version == "17.0.1"' "$tmpdir/existing.json"
```

- [ ] **Step 2: Run the test and confirm the expected failure**

Run:

```sh
nix shell nixpkgs#bash nixpkgs#jq nixpkgs#nix --command bash modules/ai/oh-my-pi/update-omp.test.sh
```

Expected: FAIL because `write_lock` does not yet exist.

- [ ] **Step 3: Implement atomic writing and CLI `main`**

Add these functions before the import-safe `main` dispatch:

```bash
write_lock() {
  local source="$1" destination="$2" tmp
  tmp="$(mktemp "${destination}.tmp.XXXXXX")"
  trap 'rm -f "$tmp"' RETURN
  cp "$source" "$tmp"
  mv "$tmp" "$destination"
  trap - RETURN
}

main() {
  local requested_version="${1:-}" repo_root release_json lock_json old_version endpoint
  [[ $# -le 1 ]] || { echo "usage: update-oh-my-pi [VERSION]" >&2; return 2; }
  [[ -z "$requested_version" || "$requested_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 2

  repo_root="$(git -C "$PWD" rev-parse --show-toplevel)"
  [[ -f "$repo_root/modules/ai/oh-my-pi/release.json" ]] || return 1
  lock_json="$repo_root/modules/ai/oh-my-pi/release.json"
  old_version="$(jq -er '.version' "$lock_json")"
  endpoint="$api_base/latest"
  [[ -z "$requested_version" ]] || endpoint="$api_base/tags/v$requested_version"

  release_json="$(mktemp)"
  trap 'rm -f "$release_json" "${release_json}.lock"' EXIT
  curl --fail --location --silent --show-error "$endpoint" > "$release_json"
  normalize_release "$release_json" "$requested_version" > "${release_json}.lock"
  write_lock "${release_json}.lock" "$lock_json"
  nix build "$repo_root#oh-my-pi"
  printf 'Updated OMP %s -> %s\n' "$old_version" "$(jq -er '.version' "$lock_json")"
}
```

Keep `curl` and `git` available through the exposed package's `runtimeInputs`. The updater must fail before `write_lock` for every release validation failure. A native build failure deliberately leaves the valid updated lock for inspection.

- [ ] **Step 4: Expose updater and check from the existing `perSystem` output**

In the module's existing `perSystem` attribute, define:

```nix
let
  updateOhMyPi = pkgs.writeShellApplication {
    name = "update-oh-my-pi";
    runtimeInputs = [ pkgs.curl pkgs.git pkgs.jq pkgs.nix ];
    text = ''
      exec ${./update-omp.sh} "$@"
    '';
  };
in
{
  packages = {
    oh-my-pi = mkOhMyPi pkgs;
    update-oh-my-pi = updateOhMyPi;
  };

  checks.oh-my-pi-update = pkgs.runCommand "oh-my-pi-update-test" {
    nativeBuildInputs = [ pkgs.bash pkgs.jq pkgs.nix ];
  } ''
    ${pkgs.bash}/bin/bash ${./update-omp.test.sh}
    touch $out
  '';
}
```

Keep the Home Manager module definition unchanged from Task 1. The package has `update-oh-my-pi` as its main executable, so `nix run .#update-oh-my-pi` invokes it directly.

- [ ] **Step 5: Run the unit check and an exact-version integration update**

Run:

```sh
nix build .#checks.x86_64-linux.oh-my-pi-update
nix run .#update-oh-my-pi -- 17.0.1
nix build .#oh-my-pi
```

Expected: the check passes; the updater replaces only `release.json` with v17.0.1 data, validates all four upstream assets, and succeeds after the native OMP package install check. Confirm the output reports `16.4.8 -> 17.0.1`.

- [ ] **Step 6: Commit the exposed updater and tested v17.0.1 update**

```sh
git add modules/ai/oh-my-pi/default.nix modules/ai/oh-my-pi/release.json modules/ai/oh-my-pi/update-omp.sh modules/ai/oh-my-pi/update-omp.test.sh
git commit -m "feat: add OMP release updater"
```
