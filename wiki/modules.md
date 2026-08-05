---
title: Modules
category: core
date: 2026-06-03
tags: [modules, dendritic, groups, import-tree]
sources: ["modules/", "CLAUDE.md", "architecture.md", "docs/superpowers/plans/2026-03-25-roles-to-groups.md"]
related: ["architecture.md", "groups.md", "ai-agents.md"]
---

# Modules

`modules/` is the single source of truth for almost all behavior. Thanks to `import-tree`, structure + naming + self-registration tell the story.

## Top-level layout (as of 2026-06-03)

```
modules/
├── ai/                 # Claude Code, Codex, grok, opencode, Pi, common, _agents.nix, _mcp.nix, skills/
├── audio/              # pipewire, easyeffects
├── base/               # fonts, meta-options, nix-defaults, stylix
├── browser/            # firefox, zen-browser
├── desktop/            # aerospace, albert, flameshot, fuzzel, gnome, kde, nautilus, nemo, swappy, swaylock, thunar, walker
├── dev/                # devenv, eve-frontier, git, helix, jujutsu, nvim (lazyvim), yaak, zed-editor
├── gaming/             # audiorelay, eve-online, gamemode, jackify, lutris, starcitizen(-lite), starsector, steam, vr
├── groups/             # developer.nix, gaming.nix, printing3d.nix (_3dp)
├── hosts/              # jezrien/, taln/  (the composition roots)
├── misc/               # appimage, distrobox, homelab, keebs, sops, ssh
├── nixos/              # 1password, btrfs, login-shell, obs-studio, razer, wooting, zsa  (NixOS-only)
├── productivity/       # obsidian
├── shell/              # atuin, carapace, default-shell, direnv, fish, nushell, starship, zoxide
├── social/             # discord
├── terminal/           # bat, btop, espanso, ghostty, kitty, ranger, sesh, television, tmux, wezterm, yazi, zellij
#                       # (see long NOTE in modules/terminal/television.nix
#                       #  about the custom files channel `source.display`)
├── virtualization/     # docker, vfio, virtman, winboat
└── (any .nix at this level or new category dirs are auto-picked up)
```

Underscore-prefixed files/dirs (`_configuration.nix`, `_mcp.nix`, `_agents.nix`, `_hardware-configuration.nix`) are **private** — import-tree skips anything with `/_` in the path.

## Registration pattern (dendritic)

A typical module file looks like:

```nix
# modules/dev/git.nix
{ ... }:
{
  flake.modules.homeManager.git = ./git.nix;   # or inline the module here
  # For NixOS-only:
  # flake.modules.nixos.my-nixos-thing = ...
}
```

Some modules are small and inline everything. Others delegate to a sibling file.

Home-manager modules are the majority for user environment.

## Groups — the user-facing composition

`modules/groups/` are the "I want this experience" bundles:

- `developer` — git, helix, nvim, zed, direnv, carapace, atuin, jujutsu?, yaak, etc. + common dev conveniences.
- `gaming` — steam, lutris, starcitizen-lite, eve-online, starsector, gamemode, jackify, ...
- `_3dp` (printing3d) — presumably 3d printing related (prusa, orca, etc. not deeply surveyed yet).

Inside a host's home-manager users section you see:

```nix
imports = with hmModules; [
  developer
  gaming
  _3dp
  # plus a few extra individual modules that aren't (yet) in a group
  ...
];
```

This is the modern replacement for the older `roles/` directory.

## Legacy roles (historical)

Older design used `roles/` (desktop, dev, gaming, terminal, server, 3dp) that were higher-level compositions. The migration to groups + dendritic made roles largely unnecessary because modules + groups can compose directly.

See the plan "roles-to-groups".

## Important base / meta modules

- `base/nix-defaults.nix`, `base/meta-options.nix`
- `nixos/` category for system-only concerns (even if some could be home)
- Many "terminal" and "shell" modules are actually home-manager (they configure user programs)

## Default shell (`ryk.defaultShell`)

One option selects the primary user's shell everywhere. `ryk.defaultShell`
(enum `fish` | `nushell` | `bash`, default `nushell`) is declared at the NixOS
layer in `modules/nixos/login-shell.nix`, which sets `users.users.<name>.shell`
and registers the choice in `/etc/shells`. A home-manager aggregator
`modules/shell/default-shell.nix` (`flake.modules.homeManager.shell`) mirrors the
value via `osConfig.ryk.defaultShell or "nushell"` — the `or` fallback keeps
nushell active on darwin, which has no NixOS `ryk` namespace — and imports the
`fish` + `nushell` submodules, each gating its **entire** config with
`lib.mkIf (config.ryk.defaultShell == "<shell>")` (so an unselected shell's
`home.packages` don't leak). Terminals (kitty/tmux/zellij/ghostty) no longer
hardcode a shell; they inherit `$SHELL` from the login shell. Hosts import the
`shell` group rather than a specific shell module. `bash` is the POSIX escape
hatch if a non-POSIX login shell trips a greeter or tool. See
`docs/superpowers/specs/2026-07-10-default-shell-design.md`.

Note: `ryk.defaultShell` and `ryk.username` are scalar **config-value** options
(plain `mkOption`, not activation toggles) in the `ryk.*` namespace declared in
`modules/base/meta-options.nix` and sibling NixOS modules.

## NFS automount

The NFS automount module defines an on-demand share mount and registers two
platform variants:

- **NixOS** — systemd automount with `noauto`; it mounts on first access,
  idle-unmounts, and fails fast when the share is unavailable.
- **Darwin** — macOS autofs with a neutral data-volume mountpoint and a
  home-manager symlink. The autofs map is installed declaratively and activated
  idempotently.

The Darwin activation splice runs late. A failure in an earlier home-manager
activation can therefore prevent it from taking effect while leaving the map
file present; treat the activation result, not the map file alone, as the
source of truth.

## AI modules — special because meta

`modules/ai/` is one of the most interesting parts of the repo:

- Shared agent definitions in `_agents.nix`
- Shared MCP server definitions in `_mcp.nix` (jcodemunch, context-mode, mempalace, context7)
- Individual agent modules: `claude-code.nix`, `codex.nix`, `grok.nix`, `opencode.nix`, `pi.nix` (hermes-agent was removed as it is only used imperatively on remote VMs)
- `common.nix` (provides mempalace wrapper bin, rtk, etc.)
- `skills/llm-wiki/` and `skills/sensitive-files/` — the skills this very wiki pattern comes from
- Permission policies per agent

Because the agents can edit the repo that defines how they are installed, this is delightfully self-referential.

See dedicated [ai-agents.md](ai-agents.md).

## How to add a new module (happy path)

1. Create `modules/<category>/my-new-thing.nix`
2. Inside: register it under the appropriate `flake.modules.<class>.my-new-thing`
3. (Optional) add it to one or more groups
4. For a host that should get it: make sure the group is imported, or import the module directly in the host home wiring
5. `nix flake check`
6. Deploy on a host
7. (Bonus) create or update a wiki page under `entities/` or extend `modules.md`

No central import list to edit. That's the point of dendritic.

## Current state of migration

Many modules have been converted. Some legacy desktop WM stuff still lives in `legacy-modules/desktop` and is explicitly imported on jezrien. Full removal of legacy is tracked in the superpowers plans (see 2026-04-05-legacy-module-final-migration etc.).

## Module naming & discoverability

- Category dirs give the first hint (you know `gaming/starcitizen-lite.nix` is gaming related).
- The registration key (the attribute name under `flake.modules.*`) is usually the same as the filename stem.
- When in doubt, `grep -r "flake.modules" modules/` or just `ls` the tree.

The wiki's job is to keep a human-readable map here so agents don't have to re-traverse the tree on every question.
