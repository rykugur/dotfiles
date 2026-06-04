---
title: Index
category: core
date: 2026-06-03
tags: [index, catalog]
sources: ["all current wiki pages"]
related: ["schema.md", "log.md"]
---

# Swoleflake LLM Wiki — Index

**Always read this file first** when working with the wiki (ingest, query, lint).

This is the content-oriented catalog. Each entry has a one-line summary and pointers to primary sources where relevant. Categories roughly follow the directory layout + core concerns.

Last major update: 2026-06-03 (initial bootstrap + first source ingest + mempalace/CLAUDE integration)

---

## Core

- [Overview](overview.md) — High-level description of Swoleflake, hosts, quick-start commands, philosophy. (sources: README, CLAUDE.md, flake.nix)
- [Architecture](architecture.md) — Dendritic loading, flake-parts + import-tree, groups, special args, home-manager integration, legacy notes. (sources: CLAUDE, design docs, host wiring)
- [Hosts](hosts.md) — jezrien, taln, nixy details, common wiring pattern, how to add a host.
- [Modules](modules.md) — Inventory and mental model of the modules/ tree, registration pattern, groups vs legacy roles, how to add a module.
- [History & Major Migrations](history.md) — The "superpowers" campaign, dendritic conversion timeline, where to find the primary design artifacts.
- [AI Agents](ai-agents.md) — First-class declarative provisioning of Claude Code, Codex, opencode, Pi, Hermes. MCP centralization, skills (including this llm-wiki), mempalace relationship, self-referentiality.

## Schema & Navigation

- [Schema & Instructions](schema.md) — This wiki's specific rules, workflows, frontmatter, directory conventions, domain notes for Nix flakes. The most important file for any agent touching the wiki.

## Sources (raw & synthesized)

- [raw/README.md](raw/README.md) — Explains the immutable raw layer and how internal vs external sources are handled.
- [2026-03-23 Dendritic Module Conversion (source)](sources/2026-03-23-dendritic-module-conversion.md) — Summary + implications of the foundational dendritic design spec.

---

## How to use this index

1. Grep or skim the one-line summaries to find candidates.
2. Follow the links (relative md links) and read the actual pages.
3. When synthesizing answers, cite the wiki pages you used.
4. After any change (ingest, major edit, new page), come back here and update the affected entries + the "last major update" date.
5. Keep one-line summaries accurate and useful — they are the primary navigation aid at small-to-medium scale.

## Growth notes

As the wiki grows we will add more categories (e.g. Concepts, Entities/jezrien, Entities/taln, Decisions, Gaming, Secrets, etc.) and may introduce Dataview queries or a small search tool. For now the flat + light subdir + excellent index is sufficient.

Initial pages created during bootstrap: the core set above + schema + this index + log.

See [log.md](log.md) for the chronological record of work on the wiki itself.
