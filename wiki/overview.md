---
title: Overview
category: core
date: 2026-06-03
tags: [swoleflake, overview, nix, flake]
sources: ["README.md", "CLAUDE.md", "flake.nix"]
related: ["architecture.md", "hosts.md", "ai-agents.md"]
---

# Overview

**Swoleflake** is a Nix flake that declaratively manages system and home configurations for multiple machines (NixOS desktops, a MacBook, and test containers) using a modern "dendritic" flake-parts + import-tree architecture, home-manager, and sops-nix for secrets.

It is the personal dotfiles / infrastructure-as-code setup for user `dusty`.

## What it provides

- Reproducible, versioned system configurations for **jezrien** (NixOS x86_64 desktop with heavy gaming + dev), **taln** (macOS aarch64), and **nixy** (NixOS LXC).
- Rich, cross-platform home environment (shells, editors, terminals, dev tools, AI agents).
- Custom packages and overlays.
- Sophisticated AI coding agent provisioning (Claude Code, Codex, opencode, Pi, Hermes) with shared skills, MCP servers, and permission policies — all managed declaratively via Nix.
- The `llm-wiki` skill itself is developed and distributed from this repo.

## Quick start (build / deploy)

See root [CLAUDE.md](https://github.com/.../CLAUDE.md) and [README.md](../README.md) for the authoritative current commands. Typical usage:

```bash
# NixOS (jezrien primary desktop)
sudo nixos-rebuild switch --flake .#jezrien

# macOS (taln)
darwin-rebuild switch --flake .#taln

# Dev shell with tools
nix develop

# Validate
nix flake check

# Update a single input
nix flake update <input-name>
```

## High level architecture (one paragraph)

Everything interesting lives under `modules/`. `flake.nix` uses `import-tree` to auto-discover and load every `.nix` file as a flake-parts module. Modules self-register into `flake.modules.nixos.*`, `flake.modules.homeManager.*`, etc. Hosts compose the right subsets (plus legacy modules during transition) and wire home-manager with special args (`hostname`, `username`, `inputs`, `outputs`). Groups in `modules/groups/` compose cross-platform feature sets (developer, gaming, 3d-printing). AI agents are first-class citizens in `modules/ai/`.

## Current hosts

| Host     | Platform          | Role                          | Key traits |
|----------|-------------------|-------------------------------|------------|
| jezrien  | x86_64-linux NixOS | Primary desktop, gaming, dev | Hyprland + niri, lots of gaming modules (Star Citizen lite, EVE, etc.), AI agents |
| taln     | aarch64-darwin    | Portable MacBook             | Aerospace WM, lighter gaming, full dev + AI tooling |
| nixy     | x86_64-linux NixOS (LXC) | Test / throwaway container  | Minimal, used for validation |

(See [hosts.md](hosts.md) for details.)

## Key directories (from the operator perspective)

- `modules/` — the heart. Auto-loaded feature modules + host wiring + groups.
- `configs/` — raw user dotfiles (fish, nu, nvim/lazyvim, wezterm, starship, tmux, etc.) symlinked by home-manager.
- `overlays/` + `pkgs/` — custom package work.
- `shells/` — dev shells (default, language-specific).
- `docs/superpowers/` — historical design docs and migration plans (the "superpowers" that drove the dendritic refactor).
- `legacy-modules/` — old structure, being drained.
- `wiki/` — this LLM-curated knowledge base (you are reading part of it).

## Philosophy

Declarative everything. Fine-grained modules over monoliths. Auto-discovery to remove toil. AI agents treated as first-class configurable software (with the same reproducibility guarantees as the rest of the system). History of decisions is preserved so the "why" doesn't get lost.

## Status

Always a work in progress (see the warning in README). Major migration to full dendritic modules was executed in a series of planned steps documented under `docs/superpowers/`.

---

*Maintained by the llm-wiki process. Last synthesized: 2026-06-03 during initial bootstrap.*
