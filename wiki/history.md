---
title: History & Major Migrations
category: migration
date: 2026-06-03
tags: [history, migration, dendritic, superpowers, refactor]
sources: ["DENDRITIC_MIGRATION.md", "docs/superpowers/plans/*.md", "docs/superpowers/specs/*.md"]
related: ["architecture.md", "overview.md"]
---

# History & Major Migrations

Swoleflake did not arrive at its current dendritic form in one leap. A deliberate, multi-month campaign of planned refactors (internally called the "superpowers" work) moved it from a more traditional flake layout to the fine-grained, auto-discovered, flake-parts-powered system that exists today.

The primary record of intent and design lives in `docs/superpowers/`:

- `plans/` — the "what we are going to do and the task list"
- `specs/` — the deeper design documents with trade-off analysis

These are **primary sources** for the wiki. When in doubt about "why is it like this?", go read the corresponding dated spec/plan.

Synthesized per-source pages live under `wiki/sources/` (e.g. [2026-03-23 Dendritic Conversion](../sources/2026-03-23-dendritic-module-conversion.md)).

## Timeline of major efforts (reverse chrono, approximate)

- **2026-05**: Pi agent module + shared MCP centralization (`pi.nix`, `_mcp.nix`)
  - Goal: give the `pi` terminal agent the same declarative Nix treatment as claude-code/opencode/codex.
  - Centralized MCP server definitions (mempalace, jcodemunch, context-mode, sequential-thinking, context7) so they are not duplicated in three places.
  - See plan `2026-05-26-pi-agent-module.md` and design `2026-05-26-pi-agent-module-design.md`.

- **2026-05**: Starcitizen lite + Sui Move dev shell
  - Lighter-weight Star Citizen support without pulling in the full broken nix-gaming stack.
  - New dev shell for Sui/Move smart contract work.

- **2026-04**: AI modules cleanup
  - Rationalization of the AI agent provisioning layer.

- **2026-04**: Legacy module final migration
  - The big push to drain `legacy-modules/`.

- **2026-03/04**: Espanso snippets
  - Nix-managed espanso configuration.

- **2026-03**: Hosts consolidation
  - Cleaned up how hosts are expressed.

- **2026-03**: Roles → Groups
  - Replaced the `roles/` concept with `groups/` (developer, gaming, 3dp) that are imported directly into home-manager user configs.
  - See plan `2026-03-25-roles-to-groups.md` + design.

- **2026-03**: Dendritic module conversion (the big one)
  - Introduced `import-tree` + flake-parts modules.
  - Renamed old `modules/` → `legacy-modules/`.
  - Every module became a self-registering flake-parts module.
  - This is the foundational change that made "drop a .nix file and it just works" a reality.
  - Foundational docs: `2026-03-23-dendritic-module-conversion*.md`
  - See the synthesized source page: [sources/2026-03-23-dendritic-module-conversion.md](sources/2026-03-23-dendritic-module-conversion.md)

- Earlier: Introduction of flake-parts, sops-nix, stylix, chaotic, various gaming flakes, the original multi-host setup.

## Dendritic pattern in one sentence

Instead of a central list that imports modules, modules import *themselves* into the flake's module registry via `flake.modules.<class>.<name> = ...`, discovered automatically by `import-tree`.

This removes a huge class of "I added a file but nothing happened" bugs and makes the tree self-describing.

## What the plans/specs are for

Each major refactor was preceded by a design doc (tradeoffs, data model, exact code shapes expected) and a plan (ordered checklist of edits + verification commands). After the work, the plan file often contains the final "as-implemented" notes.

This is excellent raw material for an llm-wiki: the specs are the "primary literature" of the system's evolution.

## Current status (as of initial wiki creation)

- Dendritic conversion is largely complete for new work.
- Legacy desktop modules still partially active on jezrien (being cleaned).
- Groups are the composition story.
- AI agents are fully declarative and include the tools that maintain this wiki (mempalace + llm-wiki skill).
- More small cleanups and feature additions are continuous (see open items in root CLAUDE.md and TODOs scattered in code).

## How to use this history as an agent

When you see an unusual pattern in the code:

1. Check if there's a corresponding dated file in `docs/superpowers/specs/` or `plans/`.
2. Read it.
3. Create or update the relevant wiki page (usually in `history.md` or a concept page) with the "why".
4. Add a cross-reference.

Never let the rationale disappear into git history alone. The wiki + the superpowers docs together should let a future agent (or future you) understand the system in depth without having to reconstruct the reasoning from diffs.

## Related

- [DENDRITIC_MIGRATION.md](../DENDRITIC_MIGRATION.md) (high-level overview written early in the process)
- Individual superpowers files (the detailed primary sources)
- [architecture.md](architecture.md) (current state description)
