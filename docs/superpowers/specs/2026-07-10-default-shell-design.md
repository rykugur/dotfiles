# Default Shell — Design

**Date:** 2026-07-10
**Status:** Approved (design)

## Goal

Introduce a single, user-definable "default shell" so the user can declare one
shell in their Nix/home-manager config and have it used **everywhere**: as the
login shell *and* as the shell every terminal / multiplexer launches. Today the
login shell is unset (defaults to bash) and nushell is hardcoded in scattered
terminal modules. This replaces that with one knob:

```nix
ryk.defaultShell = "nushell";  # or "fish" | "bash"
```

## Current state

- Two shell home-manager modules, each unconditionally `programs.<shell>.enable`:
  - `modules/shell/fish.nix`
  - `modules/nushell.nix`  (sits outside `modules/shell/`)
- **No login shell is set anywhere** — nothing assigns `users.users.<name>.shell`,
  so the OS default (bash) is the login shell. Nushell is reached only because
  terminals launch it.
- Nushell hardcoded as the launched shell in:
  - `modules/terminal/kitty.nix:23` → `shell = "${pkgs.nushell}/bin/nu --login";`
  - `modules/terminal/tmux.nix:21` → `shell = "${pkgs.nushell}/bin/nu";`
  - `modules/terminal/zellij.nix:21` → commented-out `default_shell = "nu"`.
- The `ryk` option namespace exists **only at the NixOS layer**:
  `options.ryk = { username = …; }` in `modules/base/meta-options.nix`
  (`flake.modules.nixos.meta`), plus `ryk.pipewire` / `ryk.zram` / `ryk.vfio`.
  The shells live in home-manager, where no `ryk` namespace exists yet.
- Home-manager reads system config via `osConfig` (legacy modules use the older
  `nixosConfig` alias).

## Decisions

| Decision | Choice |
|----------|--------|
| What it controls | Login shell **and** everything downstream (self-contained). |
| Coupling | Self-contained: selecting a shell enables its config *and* makes it a valid login shell. Host drops its manual shell import. |
| Option path | `ryk.defaultShell` (camelCase; consistent with existing `ryk.username`). |
| Valid values | `enum [ "fish" "nushell" "bash" ]`, default `"nushell"`. bash is the POSIX-safe escape hatch. |
| Mechanism | Approach A: system-canonical option + home-manager mirror. |
| Platform scope | NixOS only for v1 (jezrien, nixy). Darwin (taln) is future work. |

### Rejected approaches

- **Pure home-manager option** — HM cannot set `users.users.<name>.shell`, so it
  can't touch the login shell, which is the whole point.
- **Conditional imports driven by the value** (`imports = lib.optional …`) —
  imports depending on config invite infinite-recursion and push logic into
  every host. Use always-import + `lib.mkIf` gating instead.

## Design (Approach A: system-canonical + HM mirror)

### 1. System option + login-shell plumbing

Extend the NixOS layer (in `flake.modules.nixos.meta` / `modules/base/meta-options.nix`,
or a new `modules/shell/` NixOS module — implementation plan decides placement):

```nix
options.ryk.defaultShell = lib.mkOption {
  type = lib.types.enum [ "fish" "nushell" "bash" ];
  default = "nushell";
  description = "Login shell and shell used everywhere for the primary user.";
};
```

Config, keyed off `config.ryk.defaultShell`:

- Set the login shell: `users.users.${config.ryk.username}.shell = pkgs.<attr>`.
- Make the choice a **valid** login shell:
  - `fish`   → `programs.fish.enable = true` (NixOS handles `/etc/shells` + vendor bits).
  - `nushell`→ ensure `pkgs.nushell` installed and in `/etc/shells`
    (`environment.shells = [ pkgs.nushell ];`).
  - `bash`   → nothing needed (always valid).

`<attr>` maps `"fish"→pkgs.fish`, `"nushell"→pkgs.nushell`, `"bash"→pkgs.bashInteractive`.

### 2. Home-manager `shell` aggregator

New `flake.modules.homeManager.shell` (e.g. `modules/shell/default.nix`):

- Declares an HM mirror option `ryk.defaultShell`, default
  `= osConfig.ryk.defaultShell or "nushell"` (the `or` fallback keeps darwin and
  any non-NixOS eval working).
- Imports the fish + nushell submodules.
- Each submodule gates its own config on the mirror:
  `programs.<shell>.enable = lib.mkIf (config.ryk.defaultShell == "<shell>") true;`
  This refactors the existing `modules/shell/fish.nix` and (moved)
  `modules/shell/nushell.nix` so they are conditional rather than unconditional.
- `bash` needs no HM config module (interactive bash config is minimal / default).

### 3. Move nushell module into `modules/shell/`

Relocate `modules/nushell.nix` → `modules/shell/nushell.nix` so it sits alongside
`fish.nix` and the shell-adjacent tooling already in `modules/shell/`
(atuin, starship, zoxide, carapace, direnv). Update the `flake.modules.homeManager`
wiring accordingly (the attr name `nushell` can stay the same).

### 4. Remove the hardcoded shell spots

With the login shell set correctly, terminals launch it via `$SHELL` automatically:

- `modules/terminal/kitty.nix` — delete `shell = "${pkgs.nushell}/bin/nu --login";`
  (kitty launches the login shell by default).
- `modules/terminal/tmux.nix` — delete `shell = "${pkgs.nushell}/bin/nu";`
  (tmux uses `$SHELL` / the passwd shell by default).
- `modules/terminal/zellij.nix` — remove the commented `default_shell = "nu"` line.

### 5. Host wiring

- jezrien (and nixy): import the `shell` aggregator instead of `nushell`; remove
  the standalone `nushell` from the HM `imports` list. Optionally set
  `ryk.defaultShell` (default already yields nushell).
- taln (darwin): keeps working via the HM `osConfig.ryk.defaultShell or "nushell"`
  fallback; it does **not** get a login-shell change in v1. Its `nushell` import
  becomes the `shell` aggregator import (still defaults to nushell).

## Data flow

```
ryk.defaultShell (NixOS, source of truth)
  ├─ users.users.<username>.shell   → OS login shell → $SHELL in session
  │                                     → kitty / tmux inherit it (no override)
  ├─ /etc/shells + package install  → login shell is valid
  └─ osConfig → HM mirror ryk.defaultShell
                  └─ programs.<shell>.enable via mkIf  → interactive config
```

## Risk & mitigation

The user does not recall why nushell was previously removed as the login shell.
A non-POSIX login shell (nushell especially) can trip greeters, `nix develop`,
or tooling that sources `~/.profile` / expects `sh`-compatible login behavior.

**Mitigation:**
- `bash` is a first-class enum value — the escape hatch. If a greeter or tool
  breaks, `ryk.defaultShell = "bash"` restores POSIX login behavior.
- Test the switch live on jezrien (rebuild, log out/in, open kitty + tmux,
  run `nix develop`) before trusting it. nixy (LXC test container) is a lower-risk
  place to validate the login-shell plumbing first.

## Out of scope

- Darwin (taln) login-shell integration — nix-darwin's `users.users.<name>.shell`
  behaves differently and taln doesn't import `meta`. Future work.
- Renaming the `ryk` namespace repo-wide — a separate chore if desired.
- zsh support — not currently used; add to the enum later if wanted.
- Pointing per-tool integrations (starship/zoxide/direnv/carapace/atuin/yazi) at
  the shell explicitly — they already key off `programs.<shell>.enable`, which the
  gating drives correctly.

## Success criteria

- `ryk.defaultShell = "nushell"` on jezrien: after rebuild + re-login, `echo $SHELL`
  points at nushell; kitty and tmux open into nushell; no hardcoded `nu` remains.
- Switching to `ryk.defaultShell = "fish"` (or `"bash"`) changes login shell and
  all terminals with no other edits, and only the selected shell's HM config is active.
- `modules/nushell.nix` no longer exists; it lives at `modules/shell/nushell.nix`.
- `nix flake check` passes.
```
