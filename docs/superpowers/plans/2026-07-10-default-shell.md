# Default Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single `ryk.defaultShell` option that sets the primary user's login shell and drives which shell config is active everywhere, replacing hardcoded nushell in the terminal modules.

**Architecture:** A system-canonical enum option (`ryk.defaultShell`, alongside `ryk.username`) sets `users.users.<name>.shell` and makes the choice a valid login shell. A home-manager `shell` aggregator mirrors that value (via `osConfig`, with a fallback default) and gates the fish/nushell config modules with `lib.mkIf`. Terminals drop their hardcoded shell override and inherit `$SHELL`.

**Tech Stack:** Nix, flake-parts, dendritic modules (`flake.modules.{nixos,homeManager}.*`), `import-tree` auto-loading, home-manager as a NixOS module.

## Global Constraints

- Option path is exactly `ryk.defaultShell` (camelCase). Type: `lib.types.enum [ "fish" "nushell" "bash" ]`. Default: `"nushell"`.
- No `mkEnableOption` toggles — this is a config *value*, like `ryk.username`. Modules activate by import; the option only selects behavior.
- Minimal comments — only terse non-obvious "why", never restate what code does.
- A module that needs a package adds it itself; never assume the host provides it.
- Platform scope: NixOS host `jezrien` only for login-shell behavior. Darwin (`taln`) must still evaluate and build via the home-manager fallback default; it gets no login-shell change.
- `import-tree ./modules` auto-loads every `.nix` file under `modules/` except `_`-prefixed ones. New files need no flake wiring. Moving a file needs no wiring change.
- There is no unit-test framework. The verification harness is `nix eval`, `nixos-rebuild build`, and `nix flake check`. These commands ARE the tests.

**Package mapping** (used in multiple tasks):
`"fish" → pkgs.fish`, `"nushell" → pkgs.nushell`, `"bash" → pkgs.bashInteractive`.

---

### Task 1: NixOS `ryk.defaultShell` option + login-shell module

**Files:**
- Create: `modules/shell/login-shell.nix`
- Modify: `modules/hosts/jezrien/default.nix` (add module to the NixOS `modules` list)

**Interfaces:**
- Consumes: `config.ryk.username` (defined in `modules/base/meta-options.nix`, `flake.modules.nixos.meta`).
- Produces: NixOS option `config.ryk.defaultShell` (enum, default `"nushell"`); sets `config.users.users.${config.ryk.username}.shell`. The home-manager side (Task 3) reads this as `osConfig.ryk.defaultShell`.

- [ ] **Step 1: Create the login-shell NixOS module**

Create `modules/shell/login-shell.nix`:

```nix
{ ... }:
{
  flake.modules.nixos.login-shell =
    { config, lib, pkgs, ... }:
    let
      cfg = config.ryk.defaultShell;
      shellPkg = {
        fish = pkgs.fish;
        nushell = pkgs.nushell;
        bash = pkgs.bashInteractive;
      }.${cfg};
    in
    {
      options.ryk.defaultShell = lib.mkOption {
        type = lib.types.enum [ "fish" "nushell" "bash" ];
        default = "nushell";
        description = "Login shell and shell used everywhere for the primary user.";
      };

      config = {
        users.users.${config.ryk.username}.shell = shellPkg;

        # Make the chosen shell a valid login shell (/etc/shells).
        environment.shells = [ shellPkg ];

        # fish's NixOS module wires completions + /etc/shells + system integration.
        programs.fish.enable = lib.mkIf (cfg == "fish") true;
      };
    };
}
```

- [ ] **Step 2: Wire the module into jezrien**

In `modules/hosts/jezrien/default.nix`, add to the NixOS `modules` list (near the other `self.modules.nixos.*` entries, e.g. after `self.modules.nixos.meta`):

```nix
      self.modules.nixos.login-shell
```

- [ ] **Step 3: Verify the option and login shell evaluate correctly**

Run:
```bash
nix eval .#nixosConfigurations.jezrien.config.ryk.defaultShell
nix eval .#nixosConfigurations.jezrien.config.users.users.dusty.shell.pname
```
Expected:
```
"nushell"
"nushell"
```

- [ ] **Step 4: Verify the system still builds**

Run: `nixos-rebuild build --flake .#jezrien`
Expected: builds to completion, no errors (a `./result` symlink is produced).

- [ ] **Step 5: Commit**

```bash
git add modules/shell/login-shell.nix modules/hosts/jezrien/default.nix
git commit -m "feat(shell): add ryk.defaultShell option + login shell"
```

---

### Task 2: Move `nushell.nix` into `modules/shell/`

**Files:**
- Move: `modules/nushell.nix` → `modules/shell/nushell.nix` (content unchanged in this task)

**Interfaces:**
- Consumes: nothing new.
- Produces: `flake.modules.homeManager.nushell` unchanged (attr name stays `nushell`); only the file location changes. `import-tree` auto-discovers the new path.

- [ ] **Step 1: Move the file with git**

Run: `git mv modules/nushell.nix modules/shell/nushell.nix`

- [ ] **Step 2: Verify the module still resolves and builds**

Run:
```bash
nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.nushell.enable
nixos-rebuild build --flake .#jezrien
```
Expected:
```
true
```
and a clean build.

- [ ] **Step 3: Verify flake check passes**

Run: `nix flake check`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(shell): move nushell module into modules/shell/"
```

---

### Task 3: Home-manager `shell` aggregator + gate fish/nushell

**Files:**
- Create: `modules/shell/default-shell.nix` (home-manager aggregator + HM mirror option)
- Modify: `modules/shell/fish.nix` (gate all config on the selected shell)
- Modify: `modules/shell/nushell.nix` (gate `programs.nushell` on the selected shell)
- Modify: `modules/hosts/jezrien/default.nix` (replace `nushell` import with `shell`)
- Modify: `modules/hosts/taln/default.nix` (replace `nushell` import with `shell`)

**Interfaces:**
- Consumes: `osConfig.ryk.defaultShell` (from Task 1, present on NixOS; absent on darwin → falls back).
- Produces: `flake.modules.homeManager.shell` (imports fish + nushell); home-manager option `config.ryk.defaultShell` (enum, default from `osConfig`). fish/nushell modules read `config.ryk.defaultShell`.

- [ ] **Step 1: Create the home-manager aggregator with the mirror option**

Create `modules/shell/default-shell.nix`:

```nix
{ self, ... }:
{
  flake.modules.homeManager.shell =
    { config, lib, osConfig, ... }:
    {
      imports = with self.modules.homeManager; [
        fish
        nushell
      ];

      options.ryk.defaultShell = lib.mkOption {
        type = lib.types.enum [ "fish" "nushell" "bash" ];
        # Mirror the system choice; fall back for non-NixOS (darwin) eval.
        default = osConfig.ryk.defaultShell or "nushell";
        description = "Which shell's home-manager config is active.";
      };
    };
}
```

- [ ] **Step 2: Gate the fish module**

Replace the entire contents of `modules/shell/fish.nix` with:

```nix
{ ... }:
{
  flake.modules.homeManager.fish =
    { config, lib, pkgs, ... }:
    lib.mkIf (config.ryk.defaultShell == "fish") {
      home.packages = with pkgs; [
        babelfish

        grc

        fishPlugins.autopair
        fishPlugins.grc
        fishPlugins.fzf-fish
        fishPlugins.z
      ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          source ~/.dotfiles/configs/fish/config.fish
        '';
      };

      programs.fzf.enable = true;
    };
}
```

- [ ] **Step 3: Gate the nushell module**

Replace the entire contents of `modules/shell/nushell.nix` with (adds `config`/`lib` to args and wraps the config in `lib.mkIf`):

```nix
# Nushell — dendritic homeManager module
{ ... }: {
  flake.modules.homeManager.nushell = { config, lib, pkgs, ... }:
    let
      nu-scripts = pkgs.fetchFromGitHub {
        owner = "nushell";
        repo = "nu_scripts";
        rev = "e380c8a355b4340c26dc51c6be7bed78f87b0c71";
        sha256 = "sha256-b2AeWiHRz1LbiGR1gOJHBV3H56QP7h8oSTzg+X4Shk8=";
      };
    in
    lib.mkIf (config.ryk.defaultShell == "nushell") {
      programs.nushell = {
        enable = true;
        extraEnv = ''
          $env.LOCAL_CONFIG_FILE = $"($nu.data-dir)/vendor/autoload/config.nu"
          $env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
          $env.config.table.show_empty = false
          $env.config.hooks.pre_prompt = (
            $env.config.hooks.pre_prompt | append (source ${nu-scripts}/nu-hooks/nu-hooks/direnv/config.nu)
          )
          source ~/.dotfiles/configs/nu/env.nu
        '';
        extraConfig = ''
          source ${nu-scripts}/custom-menus/zoxide-menu.nu
          source ~/.dotfiles/configs/nu/config.nu
        '';
      };
    };
}
```

- [ ] **Step 4: Swap the host imports (jezrien + taln)**

In `modules/hosts/jezrien/default.nix`, in the home-manager `imports` list, replace the line:

```nix
                nushell
```
with:
```nix
                shell
```

In `modules/hosts/taln/default.nix`, in the home-manager `imports` list, replace the line:

```nix
                nushell
```
with:
```nix
                shell
```

- [ ] **Step 5: Verify gating evaluates correctly (default = nushell)**

Run:
```bash
nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.ryk.defaultShell
nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.nushell.enable
nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.fish.enable
```
Expected:
```
"nushell"
true
false
```

- [ ] **Step 6: Verify darwin still evaluates via the fallback**

Run:
```bash
nix eval .#darwinConfigurations.taln.config.home-manager.users.dusty.programs.nushell.enable
```
Expected:
```
true
```
(No `ryk.defaultShell` exists on darwin's system config, so the aggregator's `or "nushell"` fallback keeps nushell active.)

- [ ] **Step 7: Verify both hosts build**

Run:
```bash
nixos-rebuild build --flake .#jezrien
nix build .#darwinConfigurations.taln.system
```
Expected: both build cleanly.

- [ ] **Step 8: Commit**

```bash
git add modules/shell/default-shell.nix modules/shell/fish.nix modules/shell/nushell.nix modules/hosts/jezrien/default.nix modules/hosts/taln/default.nix
git commit -m "feat(shell): home-manager shell aggregator, gate fish/nushell on ryk.defaultShell"
```

---

### Task 4: Remove hardcoded shell overrides from terminals

**Files:**
- Modify: `modules/terminal/kitty.nix` (remove the `shell` setting)
- Modify: `modules/terminal/tmux.nix` (remove the `shell` setting)
- Modify: `modules/terminal/zellij.nix` (remove the commented `default_shell` line)

**Interfaces:**
- Consumes: nothing (relies on `$SHELL` from the login shell set in Task 1).
- Produces: no new interface; terminals now inherit the login shell.

- [ ] **Step 1: Remove kitty's hardcoded shell**

In `modules/terminal/kitty.nix`, delete the line:

```nix
          shell = "${pkgs.nushell}/bin/nu --login";
```

- [ ] **Step 2: Remove tmux's hardcoded shell**

In `modules/terminal/tmux.nix`, delete the line:

```nix
        shell = "${pkgs.nushell}/bin/nu";
```

- [ ] **Step 3: Remove zellij's commented default_shell**

In `modules/terminal/zellij.nix`, delete the commented line:

```nix
          # default_shell = "nu";
```

- [ ] **Step 4: Verify no hardcoded shell literal remains**

Run: `grep -rn 'bin/nu\|default_shell' modules/terminal/`
Expected: no output.

- [ ] **Step 5: Verify the build still succeeds**

Run: `nixos-rebuild build --flake .#jezrien`
Expected: clean build.

- [ ] **Step 6: Commit**

```bash
git add modules/terminal/kitty.nix modules/terminal/tmux.nix modules/terminal/zellij.nix
git commit -m "refactor(terminal): drop hardcoded nushell, inherit login shell"
```

---

### Task 5: Live end-to-end verification on jezrien

This is manual and must run on the jezrien machine (activation + relogin). It validates the login-shell risk called out in the spec.

**Files:** none (verification only).

- [ ] **Step 1: Activate the config**

Run: `sudo nixos-rebuild switch --flake .#jezrien`
Expected: activates cleanly.

- [ ] **Step 2: Confirm the login shell**

Log out and back in (or reboot), then run: `echo $SHELL`
Expected: a path ending in `/bin/nu`.

- [ ] **Step 3: Confirm terminals inherit it**

Open kitty; confirm it lands in nushell. Open tmux; confirm new panes are nushell.
Expected: nushell in both, with no error banners.

- [ ] **Step 4: Confirm dev tooling still works**

Run: `nix develop` in the repo, and confirm a greeter/session login didn't break (you reached the desktop).
Expected: `nix develop` opens a working shell.

- [ ] **Step 5: Exercise the switch + escape hatch**

Temporarily set `ryk.defaultShell = "fish";` in `modules/hosts/jezrien/_configuration.nix` (or wherever host-level `ryk.*` values are set), rebuild + relogin, confirm `echo $SHELL` ends in `/bin/fish` and kitty/tmux open fish. Then set `ryk.defaultShell = "bash";`, rebuild + relogin, confirm bash. Finally revert to `"nushell"` (or remove the line to use the default).
Expected: each switch changes the login shell and all terminals with no other edits. Bash is the POSIX escape hatch if nushell-as-login ever breaks a greeter or tool.

- [ ] **Step 6: Commit any host-level default choice**

If you settled on an explicit host value, commit it:

```bash
git add modules/hosts/jezrien/
git commit -m "chore(jezrien): set ryk.defaultShell"
```

(If you kept the module default of `"nushell"`, there is nothing to commit.)

---

## Notes for the implementer

- **Where host-level `ryk.*` values live:** `ryk.username` currently uses its module default; there's no existing host-level `ryk.*` assignment. If you set `ryk.defaultShell` per host, put it in the host's NixOS config (`modules/hosts/jezrien/_configuration.nix`), not in home-manager — the system option is the source of truth.
- **Why gate the whole fish module, not just `programs.fish.enable`:** `fish.nix` also installs `home.packages` (babelfish, plugins). Wrapping the entire attrset in `lib.mkIf` keeps those out of the profile when fish isn't selected.
- **Integrations are automatic:** `starship`, `zoxide`, `direnv`, `carapace`, `atuin`, `yazi`, `television` already set `enableFishIntegration`/`enableNushellIntegration` from `config.programs.<shell>.enable`, so gating the shells drives them with no extra edits.
- **`nix build .#darwinConfigurations.taln.system`** is the darwin build target (no `nixos-rebuild`). If unavailable on the CI/dev box, `nix eval` of the taln config (Step 6, Task 3) is the minimum darwin check.
```
