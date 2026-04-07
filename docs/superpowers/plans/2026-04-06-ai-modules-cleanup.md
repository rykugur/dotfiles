# AI Modules Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate AI modules — fold ccstatusline into claude-code, add RTK activation scripts to ai-common, wire up codex and ai-common in host configs, and clean up.

**Architecture:** Six file changes across `modules/ai/` and `modules/hosts/`. No new abstractions — just moving config between existing modules and adding HM activation scripts.

**Tech Stack:** Nix, home-manager, flake-parts

---

### Task 1: Add RTK activation scripts to `common.nix`

**Files:**
- Modify: `modules/ai/common.nix`

- [ ] **Step 1: Add activation scripts to common.nix**

Replace the full contents of `modules/ai/common.nix` with:

```nix
{ ... }:
{
  flake.modules.homeManager.ai-common =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.rtk ];

      home.activation.rtkInitClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --auto-patch
      '';

      home.activation.rtkInitOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --opencode --auto-patch
      '';

      home.activation.rtkInitCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --codex --auto-patch
      '';
    };
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/ai/common.nix
git commit -m "feat: add RTK activation scripts to ai-common module"
```

---

### Task 2: Fold ccstatusline into claude-code.nix

**Files:**
- Modify: `modules/ai/claude-code.nix`
- Delete: `modules/ai/ccstatusline.nix`

- [ ] **Step 1: Add ccstatusline config to claude-code.nix**

In `modules/ai/claude-code.nix`, add a `statusLine` key to the `claudeCodeSettings` attrset (around line 84). Change:

```nix
  claudeCodeSettings = {
    permissions = {
      allow = map (cmd: "Bash(${cmd}:*)") allowedBashCommands ++ [
        "mcp__jcodemunch__*"
        "mcp__context-mode__*"
        "mcp__plugin_context7-plugin_context7__*"
        "WebFetch(domain:github.com)"
      ];
    };
  };
```

To:

```nix
  claudeCodeSettings = {
    permissions = {
      allow = map (cmd: "Bash(${cmd}:*)") allowedBashCommands ++ [
        "mcp__jcodemunch__*"
        "mcp__context-mode__*"
        "mcp__plugin_context7-plugin_context7__*"
        "WebFetch(domain:github.com)"
      ];
    };
    statusLine = {
      type = "command";
      command = "ccstatusline";
      padding = 0;
    };
  };
```

- [ ] **Step 2: Add ccstatusline wrapper script to home.packages**

In the `flake.modules.homeManager.claude-code` section (around line 105), change:

```nix
  flake.modules.homeManager.claude-code =
    { pkgs, ... }:
    {
      home.packages = [ (mkWrappedClaudeCode pkgs) ];
```

To:

```nix
  flake.modules.homeManager.claude-code =
    { config, pkgs, ... }:
    let
      configFile = "${config.home.homeDirectory}/.dotfiles/configs/ccstatusline/settings.json";
      ccstatusline = pkgs.writeShellScriptBin "ccstatusline" ''
        exec ${pkgs.bun}/bin/bun x -y ccstatusline@latest --config "${configFile}" "$@"
      '';
    in
    {
      home.packages = [
        (mkWrappedClaudeCode pkgs)
        ccstatusline
      ];
```

- [ ] **Step 3: Delete ccstatusline.nix**

```bash
rm modules/ai/ccstatusline.nix
```

- [ ] **Step 4: Commit**

```bash
git add modules/ai/claude-code.nix
git rm modules/ai/ccstatusline.nix
git commit -m "feat: fold ccstatusline into claude-code module"
```

---

### Task 3: Remove ccstatusline from host imports

**Files:**
- Modify: `modules/hosts/jezrien/default.nix`
- Modify: `modules/hosts/taln/default.nix`

- [ ] **Step 1: Remove ccstatusline from jezrien imports**

In `modules/hosts/jezrien/default.nix`, remove the `ccstatusline` line from the `with hmModules` list (around line 71). The surrounding lines should go from:

```nix
                btop
                ccstatusline
                claude-code
```

To:

```nix
                btop
                claude-code
```

- [ ] **Step 2: Remove ccstatusline from taln imports**

In `modules/hosts/taln/default.nix`, remove the `ccstatusline` line from the `with hmModules` list (around line 48). The surrounding lines should go from:

```nix
                ai-common
                ccstatusline
                claude-code
```

To:

```nix
                ai-common
                claude-code
```

- [ ] **Step 3: Commit**

```bash
git add modules/hosts/jezrien/default.nix modules/hosts/taln/default.nix
git commit -m "chore: remove ccstatusline from host imports"
```

---

### Task 4: Build verification

- [ ] **Step 1: Check flake evaluation**

```bash
nix flake check 2>&1 | head -30
```

Expected: no evaluation errors. Warnings are OK.

- [ ] **Step 2: Build jezrien configuration**

```bash
nix build .#nixosConfigurations.jezrien.config.system.build.toplevel --dry-run 2>&1 | tail -10
```

Expected: resolves without errors. Dry-run is sufficient — we don't need to actually build.

- [ ] **Step 3: Build taln configuration**

```bash
nix build .#darwinConfigurations.taln.config.system.build.toplevel --dry-run 2>&1 | tail -10
```

Expected: resolves without errors.
