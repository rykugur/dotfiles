# AI Modules Cleanup

Consolidate AI tooling modules: add codex and ai-common modules, fold ccstatusline into claude-code, and add RTK activation scripts for all three harnesses.

## Background

The `modules/ai/` directory contains per-tool modules for AI coding harnesses. This work adds two new modules (codex, ai-common), removes one (ccstatusline) by folding it into claude-code, and introduces RTK activation scripts so `rtk init` runs automatically on every `switch`.

## Changes

### 1. `modules/ai/codex.nix` (new, already created)

Minimal module enabling the HM codex program:

```nix
programs.codex.enable = true;
```

### 2. `modules/ai/common.nix` (new, already created with `home.packages = [ pkgs.rtk ]`)

Add three unconditional home-manager activation scripts that run after `writeBoundary` on every switch:

```nix
home.activation.rtkInitClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  run ${pkgs.rtk}/bin/rtk init -g --auto-patch
'';

home.activation.rtkInitOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  run ${pkgs.rtk}/bin/rtk init -g --opencode --auto-patch
'';

home.activation.rtkInitCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  run ${pkgs.rtk}/bin/rtk init -g --codex --auto-patch
'';
```

These are unconditional because every host that imports `ai-common` also imports all three harnesses. The `--auto-patch` flag patches each harness's settings without prompting. Files written to disk by RTK for a harness that isn't installed are harmless.

Activation scripts use full Nix store paths (PATH is reset in activation context) and the `run` helper for dry-run compatibility.

### 3. `modules/ai/claude-code.nix` (modify)

Fold ccstatusline into this module:

- Add `statusLine` key to `claudeCodeSettings`:
  ```nix
  statusLine = {
    type = "command";
    command = "${ccstatusline} --config ${configFile}";
    padding = 0;
  };
  ```
  The `ccstatusline` wrapper script is defined inline (same as the current `ccstatusline.nix`): `${pkgs.bun}/bin/bun x -y ccstatusline@latest --config "${configFile}"`. The `configFile` is `${config.home.homeDirectory}/.dotfiles/configs/ccstatusline/settings.json`.

- Add the `ccstatusline` wrapper script to `home.packages` alongside the wrapped claude-code package.

The nix-wrapper-modules wrapper bakes settings into the package at build time. It does not write `~/.claude/settings.json` to disk, so RTK's `--auto-patch` and ccstatusline's install command can both write to that file without conflict.

### 4. `modules/ai/ccstatusline.nix` (delete)

Fully replaced by the fold-in to claude-code.nix.

### 5. Host configs (modify)

Remove `ccstatusline` from home-manager imports in both hosts (already have `ai-common` and `codex` added):

- `modules/hosts/jezrien/default.nix`
- `modules/hosts/taln/default.nix`

## Files touched

| File | Action |
|---|---|
| `modules/ai/codex.nix` | Already created |
| `modules/ai/common.nix` | Add activation scripts |
| `modules/ai/claude-code.nix` | Add statusLine to settings, add ccstatusline package |
| `modules/ai/ccstatusline.nix` | Delete |
| `modules/hosts/jezrien/default.nix` | Remove `ccstatusline` import |
| `modules/hosts/taln/default.nix` | Remove `ccstatusline` import |

## Out of scope

- Migrating claude-code or opencode away from nix-wrapper-modules (keeping for `nix run` portability)
- Wiring agents/skills into codex
- Adding RTK to the nix-wrapper-modules package itself (activation scripts are a HM concept, not a package concept)
