# Project Zomboid Helix Tooling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure Helix with EmmyLua LSP and globally available Umbrella Project Zomboid API stubs for Lua mod projects.

**Architecture:** `flake.nix` pins Umbrella as a non-flake source input; the lock file freezes its revision. The Home Manager Helix module launches `pkgs.emmylua-ls` and gives its `emmylua` configuration scope Umbrella's immutable Nix-store `library/` path; the existing Lua formatter remains unchanged.

**Tech Stack:** Nix flakes, flake-parts, Home Manager, Helix, nixpkgs-unstable `emmylua-ls`, PZ-Umbrella stubs.

## Global Constraints

- Keep all changes in `/home/dusty/projects/dotfiles/.worktrees/zomboid-helix` on `feat/zomboid-helix`.
- Pin Umbrella from `github:PZ-Umbrella/Umbrella` with `flake = false`.
- Use `pkgs.emmylua-ls`; do not retain LuaLS as a fallback for Lua in Helix.
- Set the EmmyLua library path to `${inputs.umbrella}/library` globally; do not create `.emmyrc.json` in mod projects.
- Preserve the existing `luaformatter` command and `auto-format = true` for Lua.
- This is declarative configuration without an existing automated test harness. Validate by evaluating the real Nix configuration and by a Helix LSP smoke test.

---

## File Structure

- Modify: `flake.nix` — declares the reproducible non-flake Umbrella source input.
- Modify: `flake.lock` — records Umbrella's resolved revision and nar hash.
- Modify: `modules/dev/helix.nix` — declares EmmyLua LSP, exposes Umbrella to it, and binds Lua files to that server.
- Create: `docs/superpowers/specs/2026-08-11-zomboid-helix-design.md` — already committed design record; do not modify during implementation.

### Task 1: Pin Umbrella and configure EmmyLua for Helix

**Files:**
- Modify: `flake.nix:73-88`
- Modify: `flake.lock`
- Modify: `modules/dev/helix.nix:87-105,327-332`
- Test: evaluated `nix flake check --no-build` and generated Helix configuration

**Interfaces:**
- Consumes: `inputs` passed to `flake.modules.homeManager.helix` at `modules/dev/helix.nix:1`; `pkgs.emmylua-ls` supplied by the unstable nixpkgs input.
- Produces: the `umbrella` flake input and an `emmylua-ls` Helix language server with `config.workspace.library = [ "${inputs.umbrella}/library" ]`; the `lua` language uses `[ "emmylua-ls" ]`.

- [ ] **Step 1: Establish the pre-change failure condition**

Run from the worktree:

```bash
nix eval --raw nixpkgs#emmylua-ls.name
nix flake metadata --json | jq -e '.locks.nodes.umbrella'
```

Expected: the first command prints the available package name (currently `emmylua_ls-0.24.0`); the second fails because the `umbrella` lock node does not exist. This proves the missing pinned source before editing.

- [ ] **Step 2: Add the Umbrella flake input**

In `flake.nix`, add this entry under the existing `### random stuff` inputs, immediately after `helix.url`:

```nix
    umbrella = {
      url = "github:PZ-Umbrella/Umbrella";
      flake = false;
    };
```

Do not add a `nixpkgs.follows` entry: Umbrella is a source tree, not a Nix flake.

- [ ] **Step 3: Lock the new input and verify the source layout**

Run:

nix flake lock --update-input umbrella
nix flake metadata --json | jq -e '
  .locks.nodes.umbrella.locked
  | select(.rev | strings and length > 0)
  | select(.narHash | strings and length > 0)
'
```

Expected: the query prints Umbrella's non-empty pinned `rev` and `narHash`. This verifies the source's immutable lock record; no flake output evaluates a raw source input directly.

- [ ] **Step 4: Replace the LuaLS definition with EmmyLua**

In `modules/dev/helix.nix`, replace:

```nix
            lua-language-server = {
              command = "${pkgs.lua-language-server}/bin/lua-language-server";
            };
```

with:

```nix
            emmylua-ls = {
              command = lib.getExe pkgs.emmylua-ls;
              config.workspace.library = [ "${inputs.umbrella}/library" ];
            };
```

This uses Nix's executable metadata instead of duplicating the binary filename and passes the library through Helix's LSP `config` object under the EmmyLua `emmylua` client configuration scope.

- [ ] **Step 5: Bind Lua to EmmyLua without changing formatting**

In the existing `language` entry with `name = "lua"`, insert the LSP binding between `auto-format` and `formatter`:

```nix
              language-servers = [ "emmylua-ls" ];
```

The resulting complete Lua entry must be:

```nix
            {
              name = "lua";
              auto-format = true;
              language-servers = [ "emmylua-ls" ];
              formatter = {
                command = "${pkgs.luaformatter}/bin/lua-format";
              };
            }
```

- [ ] **Step 6: Evaluate the resulting configuration**

Run:

```bash
nix flake check --no-build
nix eval --raw nixpkgs#emmylua-ls.name
```

Expected: `nix flake check --no-build` exits zero; the package evaluation prints a non-empty `emmylua_ls-*` name. Do not treat existing warnings about the flake's `modules` output or incompatible systems as failures.

- [ ] **Step 7: Inspect the generated Home Manager Helix settings**

Run the NixOS configuration evaluation for the Linux host that imports the Helix Home Manager module:

```bash
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.helix.languages \
  | jq -e '
      ."language-server"."emmylua-ls".command
      and ."language-server"."emmylua-ls".config.workspace.library[0]
      and ([.language[] | select(.name == "lua") | ."language-servers"] == [["emmylua-ls"]])
    '
```

Expected: `true`. Then inspect the resolved values:

```bash
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.helix.languages \
  | jq '{
      command: ."language-server"."emmylua-ls".command,
      library: ."language-server"."emmylua-ls".config.workspace.library,
      luaServers: [.language[] | select(.name == "lua") | ."language-servers"]
    }'
```

Expected: `command` is a Nix-store executable ending in `emmylua_ls`; `library[0]` is a Nix-store path ending in `/library`; `luaServers` is `[["emmylua-ls"]]`.

- [ ] **Step 8: Smoke-test the real LSP startup**

Create a temporary directory outside the repository containing `mod.lua`:

```lua
local player = getPlayer()
player:getUsername()
```

Start Helix from that directory with the generated Home Manager configuration active, open `mod.lua`, wait for LSP initialization, and run `:log-open` or inspect the Helix log. Expected: Helix starts `emmylua_ls` without an executable or configuration error. Confirm a PZ symbol such as `getPlayer` receives hover/completion data from Umbrella when Helix exposes it.

Remove the temporary directory after observing the result.

- [ ] **Step 9: Commit the implementation**

```bash
git add flake.nix flake.lock modules/dev/helix.nix
git commit -m "feat: add Zomboid Lua tooling to Helix"
```

Expected: the commit contains only the flake input/lock changes and Helix configuration changes; retain the already committed design document as its own commit.

## Plan Self-Review

- **Spec coverage:** Task 1 pins Umbrella, installs and configures `pkgs.emmylua-ls`, binds it solely to Lua, exposes `${inputs.umbrella}/library` globally, preserves Lua formatting, and verifies evaluation plus LSP startup.
- **Placeholder scan:** No deferred implementation, ambiguous validation, or unspecified file path remains.
- **Type/config consistency:** The same server identifier, `emmylua-ls`, is declared in the server map and referenced by the Lua language entry. The library path uses the same `inputs.umbrella` input declared by the flake change.
