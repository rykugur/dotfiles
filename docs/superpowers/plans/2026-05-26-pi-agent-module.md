# Pi Agent Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `pi` coding-agent module with four extensions (pi-subagents, pi-mcp-adapter, pi-lens, pi-permission-system) and three skills, wired declaratively via `pi.nix`'s home-manager module. Centralize MCP server definitions across `claude-code`, `opencode`, and `pi` into a shared `_mcp.nix`.

**Architecture:** `_mcp.nix` exports canonical `{command, args, env?}` server definitions and per-tool serializers (`toClaudeCode`, `toOpencode`, `toPi`). The `pi` module imports `inputs.pi.homeModules.default` and passes extensions + skills as store paths via the upstream module's `listOf path` options — no imperative `pi install`. Permission policy and MCP config land as `home.file` entries under `~/.pi/agent/`.

**Tech Stack:** Nix flakes (flake-parts, dendritic pattern), home-manager, `pi.nix` upstream module, `nix-wrapper-modules` (existing, unchanged).

**Spec:** `docs/superpowers/specs/2026-05-26-pi-agent-module-design.md`

---

## File Structure

**Created:**
- `modules/ai/_mcp.nix` — canonical MCP server definitions + per-tool serializers
- `modules/ai/pi.nix` — home-manager module for pi coding-agent

**Modified:**
- `flake.nix` — new inputs + cachix substituter
- `flake.lock` — refreshed by `nix flake lock`
- `modules/ai/claude-code.nix` — consume `_mcp.nix` instead of inline MCP defs
- `modules/ai/opencode.nix` — consume `_mcp.nix` instead of inline MCP defs
- `modules/hosts/taln/default.nix` — import `pi` home-manager module
- `modules/hosts/jezrien/default.nix` — import `pi` home-manager module

---

## Verification approach (Nix-specific)

This codebase has no unit-test runner for Nix files. TDD-style verification uses:

- **`nix flake check`** — evaluates all flake outputs across declared systems
- **`darwin-rebuild build --flake .#taln`** — builds (without switching) the Darwin host; user runs on Darwin, so this is the primary smoke test
- **`nix eval --json <path>`** — extracts rendered config from the flake; used to verify behavior preservation across the refactor
- **`nix path-info` / derivation-hash comparison** — confirms that two builds produce byte-identical outputs

For behavior-preserving refactors (Tasks 1-7), the contract is: derivation hash of the wrapped agent package must be unchanged. Different hash → JSON output differs → refactor regressed.

---

## Phase 1 — `_mcp.nix` refactor (behavior-preserving)

### Task 1: Capture pre-refactor baseline

**Files:**
- Read: `modules/ai/claude-code.nix`, `modules/ai/opencode.nix`

- [ ] **Step 1: Capture rendered opencode MCP config**

Run:
```bash
nix eval --json '.#darwinConfigurations.taln.config.home-manager.users.dusty.programs.opencode.settings.mcp' \
  | jq -S . > /tmp/opencode-mcp-before.json
```

Expected: file exists, valid JSON, contains keys `jcodemunch`, `context-mode`, `sequential-thinking`, `context7`.

- [ ] **Step 2: Capture taln system derivation hash**

Run:
```bash
nix eval --raw '.#darwinConfigurations.taln.system.outPath' > /tmp/taln-system-before.txt
cat /tmp/taln-system-before.txt
```

Expected: a `/nix/store/<hash>-darwin-system-<version>` path. Save this hash; we'll compare it after the refactor. A byte-identical refactor produces the same hash.

- [ ] **Step 3: Do not commit yet — these are scratch files**

No `git add`. These live in `/tmp/` and will be compared in Task 6.

---

### Task 2: Create `_mcp.nix`

**Files:**
- Create: `modules/ai/_mcp.nix`

- [ ] **Step 1: Write the file**

Create `modules/ai/_mcp.nix` with this exact content:

```nix
{ pkgs }:
let
  inherit (pkgs) lib;

  servers = {
    jcodemunch = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--python"
        "3.13"
        "jcodemunch-mcp"
      ];
    };
    context-mode = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "context-mode"
      ];
      env = {
        PATH = "${pkgs.nodejs}/bin:${pkgs.coreutils}/bin:/bin:/usr/bin";
      };
    };
    mempalace = {
      command = "${pkgs.uv}/bin/uv";
      args = [
        "run"
        "--with"
        "mempalace"
        "--python"
        "3.13"
        "python"
        "-m"
        "mempalace.mcp_server"
      ];
    };
    sequential-thinking = {
      command = "${pkgs.bun}/bin/bunx";
      args = [ "@modelcontextprotocol/server-sequential-thinking" ];
    };
    context7 = {
      command = "${pkgs.bun}/bin/bunx";
      args = [ "@upstash/context7-mcp" ];
    };
  };

  pick = names: lib.getAttrs names servers;

  # Claude Code mcpConfig schema: { type = "stdio"; command; args; env?; }
  toClaudeCode =
    serverSet:
    lib.mapAttrs (
      _: s:
      {
        type = "stdio";
        inherit (s) command args;
      }
      // lib.optionalAttrs (s ? env) { inherit (s) env; }
    ) serverSet;

  # Opencode programs.opencode.settings.mcp schema:
  # { type = "local"; command = [cmd args...]; environment?; }
  toOpencode =
    serverSet:
    lib.mapAttrs (
      _: s:
      {
        type = "local";
        command = [ s.command ] ++ s.args;
      }
      // lib.optionalAttrs (s ? env) { environment = s.env; }
    ) serverSet;

  # Pi mcp.json schema is the canonical form unchanged.
  toPi = serverSet: serverSet;
in
{
  inherit
    servers
    pick
    toClaudeCode
    toOpencode
    toPi
    ;
}
```

- [ ] **Step 2: Sanity-check eval**

Run:
```bash
nix eval --impure --expr '
  let
    pkgs = import <nixpkgs> {};
    mcp = import ./modules/ai/_mcp.nix { inherit pkgs; };
  in builtins.attrNames mcp
'
```

Expected output (set ordering may vary):
```
[ "pick" "servers" "toClaudeCode" "toOpencode" "toPi" ]
```

- [ ] **Step 3: Sanity-check `toOpencode` output shape**

Run:
```bash
nix eval --json --impure --expr '
  let
    pkgs = import <nixpkgs> {};
    mcp = import ./modules/ai/_mcp.nix { inherit pkgs; };
  in mcp.toOpencode (mcp.pick [ "sequential-thinking" ])
'
```

Expected (paths will differ):
```json
{
  "sequential-thinking": {
    "type": "local",
    "command": ["/nix/store/.../bin/bunx", "@modelcontextprotocol/server-sequential-thinking"]
  }
}
```

- [ ] **Step 4: Stage but do not commit**

```bash
git add modules/ai/_mcp.nix
```

(We commit after the refactor is verified.)

---

### Task 3: Refactor `claude-code.nix` to use `_mcp.nix`

**Files:**
- Modify: `modules/ai/claude-code.nix:46-86`

- [ ] **Step 1: Replace the `mkClaudeCodeMcpConfig` definition**

In `modules/ai/claude-code.nix`, locate lines 46-86 — the entire `mkClaudeCodeMcpConfig = pkgs: { ... };` block. Replace it with:

```nix
  mkClaudeCodeMcpConfig =
    pkgs:
    let
      mcp = import ./_mcp.nix { inherit pkgs; };
    in
    mcp.toClaudeCode (mcp.pick [
      "jcodemunch"
      "context-mode"
      "mempalace"
      "sequential-thinking"
    ]);
```

Keep everything before and after unchanged.

- [ ] **Step 2: Eval-check**

Run:
```bash
nix flake check --no-build 2>&1 | tail -20
```

Expected: no eval errors. (Build derivations may be skipped with `--no-build`; we just want eval to succeed.)

---

### Task 4: Refactor `opencode.nix` to use `_mcp.nix`

**Files:**
- Modify: `modules/ai/opencode.nix:70-105`

- [ ] **Step 1: Replace the `mcp` attrset inside `mkOpencodeSettings`**

In `modules/ai/opencode.nix`, locate the `mcp = { ... };` block inside `mkOpencodeSettings = pkgs: { ... }` (currently lines 70-105). Replace the entire `mcp = { ... };` value with:

```nix
    mcp =
      let
        mcp = import ./_mcp.nix { inherit pkgs; };
      in
      mcp.toOpencode (mcp.pick [
        "jcodemunch"
        "context-mode"
        "sequential-thinking"
        "context7"
      ]);
```

Note the local binding shadows the outer name — that's fine since it's scoped to the `let`.

Keep everything else in `mkOpencodeSettings` unchanged.

- [ ] **Step 2: Eval-check**

Run:
```bash
nix flake check --no-build 2>&1 | tail -20
```

Expected: no eval errors.

---

### Task 5: Verify opencode MCP rendering is byte-identical

**Files:**
- Read: `/tmp/opencode-mcp-before.json`

- [ ] **Step 1: Capture post-refactor opencode MCP**

Run:
```bash
nix eval --json '.#darwinConfigurations.taln.config.home-manager.users.dusty.programs.opencode.settings.mcp' \
  | jq -S . > /tmp/opencode-mcp-after.json
```

- [ ] **Step 2: Diff before/after**

Run:
```bash
diff /tmp/opencode-mcp-before.json /tmp/opencode-mcp-after.json
```

Expected: no output (files identical).

If diff is non-empty: investigate. Likely causes:
- Attr order differences (shouldn't happen after `jq -S`)
- A field accidentally added or dropped during the refactor — re-read `toOpencode` in `_mcp.nix` and the original `mcp = { ... }` block in `opencode.nix`.

Do not proceed until diff is empty.

---

### Task 6: Verify taln system hash is byte-identical

**Files:**
- Read: `/tmp/taln-system-before.txt`

- [ ] **Step 1: Capture post-refactor taln system hash**

Run:
```bash
nix eval --raw '.#darwinConfigurations.taln.system.outPath' > /tmp/taln-system-after.txt
diff /tmp/taln-system-before.txt /tmp/taln-system-after.txt
```

Expected: no output (paths identical → same input hash → byte-identical rendered config across the entire taln system).

If diff is non-empty, the refactor changed *something* that propagated into the system derivation. Most likely culprits:

1. **Attr order in JSON output.** `builtins.toJSON` sorts keys alphabetically, so this should be stable — but if `nix-wrapper-modules` serializes via a different path, order could shift. Inspect the difference by drilling in:

```bash
# Find the claude-code wrapped derivation path in both
nix eval --raw '.#darwinConfigurations.taln.config.home-manager.users.dusty.home.packages' \
  --apply 'ps: builtins.concatStringsSep "\n" (map (p: p.outPath) ps)' \
  | grep -i claude
```

2. **A field was added or dropped during refactor.** Re-read the original `mkClaudeCodeMcpConfig` (in your editor's history or via `git diff HEAD`) and confirm `toClaudeCode` produces the same shape.

3. **`env` field handling differs.** Only `context-mode` has `env`; verify `toClaudeCode` emits it correctly.

- [ ] **Step 2: Build taln to confirm it still compiles**

```bash
darwin-rebuild build --flake .#taln 2>&1 | tail -10
```

Expected: successful build. (If Step 1 showed identical hashes, this should be a no-op cache hit.)

Do not proceed to Task 7 until either the hashes match, or you've affirmatively confirmed the only change is attr ordering in equivalent JSON.

---

### Task 7: Commit the refactor

- [ ] **Step 1: Stage refactor files**

```bash
git add modules/ai/_mcp.nix modules/ai/claude-code.nix modules/ai/opencode.nix
```

- [ ] **Step 2: Commit**

```bash
git commit -m "$(cat <<'EOF'
refactor(modules/ai): extract MCP server defs into _mcp.nix

Single source of truth for jcodemunch, context-mode, mempalace,
sequential-thinking, and context7. Per-tool serializers
(toClaudeCode, toOpencode, toPi) translate the canonical
{command, args, env?} form into each agent's schema.

Behavior-preserving: rendered opencode MCP config and
claude-code wrapped derivation hash unchanged.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Verify clean status**

```bash
git status
```

Expected: still see `M modules/terminal/espanso.nix` (pre-existing, untouched) and any new pi files we haven't added yet. No other unstaged changes from the refactor.

---

## Phase 2 — `pi` module + extensions

### Task 8: Add flake inputs and cachix substituter

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Add the `pi` flake input**

In `flake.nix`, locate the `### ai stuff` section (currently lines 79-112). Add immediately after the `hermes-webui` block (before the `#  plugins` comment at line 90):

```nix
    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-subagents = {
      url = "github:nicobailon/pi-subagents";
      flake = false;
    };
    pi-mcp-adapter = {
      url = "github:nicobailon/pi-mcp-adapter";
      flake = false;
    };
    pi-lens = {
      url = "github:apmantza/pi-lens";
      flake = false;
    };
    pi-permission-system = {
      url = "github:MasuRii/pi-permission-system";
      flake = false;
    };
```

- [ ] **Step 2: Add cachix substituter**

In `flake.nix`, locate the `nixConfig` block (currently lines 168-181). Append to `extra-substituters`:

```nix
      "https://pi.cachix.org"
```

Append to `extra-trusted-public-keys`:

```nix
      "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
```

- [ ] **Step 3: Lock the new inputs**

Run:
```bash
nix flake lock
```

Expected: lockfile updated. Five new entries added to `flake.lock`: `pi`, `pi-subagents`, `pi-mcp-adapter`, `pi-lens`, `pi-permission-system`.

If `nix flake lock` errors on the cachix substituter (e.g. asks for confirmation), pass `--accept-flake-config`:
```bash
nix flake lock --accept-flake-config
```

- [ ] **Step 4: Eval-check**

```bash
nix flake check --no-build 2>&1 | tail -20
```

Expected: no eval errors. The new inputs are referenced but not yet consumed.

---

### Task 9: Create `modules/ai/pi.nix` skeleton

**Files:**
- Create: `modules/ai/pi.nix`

- [ ] **Step 1: Write the skeleton with extensions and skills only**

Create `modules/ai/pi.nix` with this exact content:

```nix
{ inputs, ... }:
let
  extensions = [
    inputs.pi-subagents
    inputs.pi-mcp-adapter
    inputs.pi-lens
    inputs.pi-permission-system
  ];

  skills = [
    {
      name = "frontend-design";
      src = "${inputs.skills-anthropic}/skills/frontend-design";
    }
    {
      name = "web-design-guidelines";
      src = "${inputs.skills-vercel}/skills/web-design-guidelines";
    }
    {
      name = "karpathy-guidelines";
      src = "${inputs.karpathy-skills}/skills/karpathy-guidelines";
    }
  ];
in
{
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    {
      imports = [ inputs.pi.homeModules.default ];

      programs.pi.coding-agent = {
        enable = true;
        inherit extensions;
        skills = map (s: s.src) skills;
      };
    };
}
```

- [ ] **Step 2: Eval-check**

```bash
nix flake check --no-build 2>&1 | tail -20
```

Expected: no eval errors. The `flake.modules.homeManager.pi` output now exists but isn't consumed by any host yet — the next task adds MCP config; host wiring comes in Task 13.

---

### Task 10: Add MCP config to `pi.nix`

**Files:**
- Modify: `modules/ai/pi.nix`

- [ ] **Step 1: Add `mkPiMcpConfig` helper and the `home.file` entry**

In `modules/ai/pi.nix`, modify the `let` block to add `mkPiMcpConfig`, and add a `home.file` entry inside the home-manager module.

Replace the entire current file contents with:

```nix
{ inputs, ... }:
let
  extensions = [
    inputs.pi-subagents
    inputs.pi-mcp-adapter
    inputs.pi-lens
    inputs.pi-permission-system
  ];

  skills = [
    {
      name = "frontend-design";
      src = "${inputs.skills-anthropic}/skills/frontend-design";
    }
    {
      name = "web-design-guidelines";
      src = "${inputs.skills-vercel}/skills/web-design-guidelines";
    }
    {
      name = "karpathy-guidelines";
      src = "${inputs.karpathy-skills}/skills/karpathy-guidelines";
    }
  ];

  mkPiMcpConfig =
    pkgs:
    let
      mcp = import ./_mcp.nix { inherit pkgs; };
    in
    {
      mcpServers = mcp.toPi (mcp.pick [
        "jcodemunch"
        "context-mode"
        "mempalace"
        "sequential-thinking"
        "context7"
      ]);
    };
in
{
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    {
      imports = [ inputs.pi.homeModules.default ];

      programs.pi.coding-agent = {
        enable = true;
        inherit extensions;
        skills = map (s: s.src) skills;
      };

      home.file.".pi/agent/mcp.json".text = builtins.toJSON (mkPiMcpConfig pkgs);
    };
}
```

- [ ] **Step 2: Eval-check the rendered MCP file**

Run:
```bash
nix eval --raw '.#darwinConfigurations.taln.config.home-manager.users.dusty.home.file.".pi/agent/mcp.json".text' \
  | jq -S .
```

Expected: a JSON object with a top-level `mcpServers` key containing `jcodemunch`, `context-mode`, `mempalace`, `sequential-thinking`, `context7`.

This will fail at this point because we haven't wired `pi` into the taln host yet (Task 13). If the eval errors with "attribute 'pi' missing" — that's expected, move on. We'll re-run after Task 13.

If the eval errors mention `inputs.pi.homeModules.default` not existing: the upstream module path may differ. Check `nix eval --raw '.#inputs.pi.homeModules' --apply 'builtins.attrNames'` and adjust the import.

---

### Task 11: Add permission policy to `pi.nix`

**Files:**
- Modify: `modules/ai/pi.nix`

- [ ] **Step 1: Add `piPermissionsPolicy` and the second `home.file` entry**

In `modules/ai/pi.nix`, insert `piPermissionsPolicy` into the `let` block (after `mkPiMcpConfig`), and add the corresponding `home.file` entry.

Add to the `let` block:

```nix
  piPermissionsPolicy = {
    defaultPolicy = "allow";

    bash = {
      "*" = "allow";
      "rm *" = "deny";
      "npm *" = "deny";
      "kubectl get *" = "allow";
      "kubectl logs *" = "allow";
      "flux get *" = "allow";
    };

    mcp = {
      "jcodemunch.*" = "allow";
      "context7.*" = "allow";
      "context-mode.ctx_*" = "allow";
      "mempalace.*" = "allow";
      "sequential-thinking.*" = "allow";
    };

    skills = {
      "frontend-design" = "allow";
      "web-design-guidelines" = "allow";
      "karpathy-guidelines" = "allow";
    };

    special = {
      read = {
        "*" = "allow";
        "*.env" = "deny";
        "*.env.*" = "deny";
        ".envrc" = "deny";
        "*.sops.yaml" = "deny";
        "*.tfvars" = "deny";
        "*.env.example" = "allow";
      };
    };
  };
```

Add to the home-manager module body (after the existing `home.file."./pi/agent/mcp.json"` entry):

```nix
      home.file.".pi/agent/pi-permissions.jsonc".text = builtins.toJSON piPermissionsPolicy;
```

- [ ] **Step 2: Verify against pi-permission-system schema**

Read the upstream schema before relying on these key names:

```bash
nix eval --raw '.#inputs.pi-permission-system.outPath' 2>&1 | head -1
```

Then inspect the README/schema docs at that path for the exact JSONC structure (key names, wildcard syntax for MCP and bash entries). If they differ from what's in the policy above, edit `piPermissionsPolicy` to match.

Common things to verify:
- Top-level key: `defaultPolicy` vs `default_policy` vs `default`
- MCP wildcard form: `serverName.*` vs `serverName_*` vs `serverName/toolName`
- `special.read` vs a top-level `read` section

- [ ] **Step 3: Eval the rendered policy**

Run:
```bash
nix eval --raw '.#darwinConfigurations.taln.config.home-manager.users.dusty.home.file.".pi/agent/pi-permissions.jsonc".text' \
  | jq -S .
```

(Same caveat as Task 10 Step 2 — may fail until Task 13 wires pi into taln. If so, defer this check to after Task 13.)

Expected: JSON object with the policy fields above.

---

### Task 12: Stage the new pi module (no commit yet)

- [ ] **Step 1: Stage**

```bash
git add modules/ai/pi.nix flake.nix flake.lock
```

- [ ] **Step 2: Verify staged content**

```bash
git diff --cached --stat
```

Expected: 3 files staged — `flake.lock` (modified), `flake.nix` (modified), `modules/ai/pi.nix` (new).

---

### Task 13: Wire `pi` into the `taln` host

**Files:**
- Modify: `modules/hosts/taln/default.nix:40-57`

- [ ] **Step 1: Add `pi` to the imports list**

In `modules/hosts/taln/default.nix`, locate the imports list (lines 40-57). It currently reads:

```nix
              imports = with hmModules; [
                # group
                developer

                # individual modules (not in developer group)
                ai-common
                claude-code
                codex
                espanso
                homelab
                nushell
                obsidian
                opencode
                sops
                ssh
                eve-frontier
                television
              ];
```

Add `pi` alphabetically between `opencode` and `sops`:

```nix
              imports = with hmModules; [
                # group
                developer

                # individual modules (not in developer group)
                ai-common
                claude-code
                codex
                espanso
                homelab
                nushell
                obsidian
                opencode
                pi
                sops
                ssh
                eve-frontier
                television
              ];
```

- [ ] **Step 2: Re-verify the eval checks from Tasks 10 & 11**

Run:
```bash
nix eval --raw '.#darwinConfigurations.taln.config.home-manager.users.dusty.home.file.".pi/agent/mcp.json".text' | jq -S . | head -30
nix eval --raw '.#darwinConfigurations.taln.config.home-manager.users.dusty.home.file.".pi/agent/pi-permissions.jsonc".text' | jq -S . | head -30
```

Expected: both render their respective JSON without errors. If either fails, return to Task 10 or 11 and fix.

---

### Task 14: Wire `pi` into the `jezrien` host

**Files:**
- Modify: `modules/hosts/jezrien/default.nix:69-98`

- [ ] **Step 1: Add `pi` to the imports list**

In `modules/hosts/jezrien/default.nix`, locate the imports list (currently lines 69-98). Add `pi` alphabetically between `opencode` (line 89) and `sops` (line 91, currently `# sesh` is between them — sesh is commented out).

After the change, the relevant section should look like:

```nix
                obsidian
                opencode
                pi
                # sesh
                sops
```

- [ ] **Step 2: Eval-check jezrien from this Darwin host**

```bash
nix eval --raw '.#nixosConfigurations.jezrien.config.system.build.toplevel.drvPath' 2>&1 | tail -5
```

Expected: a `/nix/store/<hash>-nixos-system-jezrien-<version>.drv` path. If eval errors: read the error, fix.

Note: this only confirms that jezrien's NixOS configuration *evaluates*. Actually building requires an x86_64-linux machine (or remote builder / QEMU). Don't attempt the build from Darwin.

---

### Task 15: Build taln and smoke-test

- [ ] **Step 1: Build (no switch)**

```bash
darwin-rebuild build --flake .#taln 2>&1 | tail -20
```

Expected: successful build, no errors. May pull from `pi.cachix.org` — should be fast.

If the build errors with "extensions" or "skills" not accepting paths: the upstream `pi.nix` module's option types may have changed. Check `nix eval --raw '.#inputs.pi.outPath'` and re-read `coding-agent/options.nix` in the pi.nix repo.

If a specific extension fails (e.g. `pi-lens` requires `npm install` or similar before being usable as a path): the design assumes extensions load directly from source. If pi rejects an extension path, you may need to wrap it in `pkgs.runCommand` or `pkgs.buildNpmPackage` — escalate to the user before doing this; it changes the design.

- [ ] **Step 2: Inspect the rendered pi config files**

```bash
RESULT=$(darwin-rebuild build --flake .#taln --print-out-paths 2>/dev/null | tail -1)
find $RESULT -path '*home-files*/.pi/agent/*' 2>/dev/null | head -5
```

Expected: paths for `mcp.json` and `pi-permissions.jsonc` under the home-files derivation.

Cat one to confirm shape:
```bash
find $RESULT -path '*home-files*/.pi/agent/mcp.json' -exec cat {} \; | jq .
```

Expected: valid JSON with `mcpServers` containing the five servers.

---

### Task 16: Commit and clean up

- [ ] **Step 1: Stage host changes**

```bash
git add modules/hosts/taln/default.nix modules/hosts/jezrien/default.nix
```

- [ ] **Step 2: Verify the full staged diff**

```bash
git diff --cached --stat
```

Expected files staged:
- `flake.lock` (modified)
- `flake.nix` (modified)
- `modules/ai/pi.nix` (new)
- `modules/hosts/jezrien/default.nix` (modified)
- `modules/hosts/taln/default.nix` (modified)

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(modules/ai): add pi coding-agent module

Wires pi.nix's home-manager module with four extensions
(pi-subagents, pi-mcp-adapter, pi-lens, pi-permission-system),
three skills (frontend-design, web-design-guidelines,
karpathy-guidelines), the shared MCP server set, and an
OpenCode-style permission policy.

Extensions are loaded declaratively from flake inputs as store
paths via the upstream module's --extension/--skill flags. No
imperative `pi install` or mutable ~/.pi/ state.

Adds pi.cachix.org as a trusted substituter and imports the
module on taln and jezrien.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify clean status**

```bash
git status
```

Expected: only `M modules/terminal/espanso.nix` remaining (pre-existing, unrelated).

- [ ] **Step 5: Remove scratch files**

```bash
rm -f /tmp/opencode-mcp-before.json /tmp/opencode-mcp-after.json \
      /tmp/claude-code-drv-before.txt /tmp/claude-code-drv-after.txt \
      /tmp/taln-dryrun-before.txt /tmp/taln-build-after.txt
```

---

## Done

Two commits land on the branch:

1. `refactor(modules/ai): extract MCP server defs into _mcp.nix`
2. `feat(modules/ai): add pi coding-agent module`

To activate on taln after merge:

```bash
darwin-rebuild switch --flake .#taln
```

Then verify pi launches with its extensions loaded:

```bash
pi --version
pi --help | grep -E 'extension|skill'
```

The actual functional test of subagents / lens / mcp-adapter / permission-system is a runtime concern, not a build-time one — exercise them in a real pi session after activation.
