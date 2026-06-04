---
title: AI Agents
category: ai
date: 2026-06-03
tags: [ai, agents, claude-code, codex, grok, opencode, pi, mempalace, llm-wiki, skills, mcp]
sources: ["modules/ai/", "modules/ai/_agents.nix", "modules/ai/_mcp.nix", "modules/ai/claude-code.nix", "modules/ai/grok.nix", "modules/ai/pi.nix", "modules/ai/common.nix", "modules/ai/skills/llm-wiki/SKILL.md"]
related: ["overview.md", "architecture.md", "modules.md"]
---

# AI Agents

One of the most distinctive parts of Swoleflake is that AI coding agents are treated as **first-class, declaratively managed software** — exactly like shells, editors, or window managers.

The goal: identical (or as close as the host allows) agent experience on every machine, installed and configured purely through Nix, with no imperative `claude install ...` or `pi install npm:...` steps that leave state in `~/.claude/` or `~/.pi/`.

## The agents

- **claude-code** (Anthropic's Claude Code)
- **codex** (OpenAI Codex / successor agent)
- **grok** (superagent-ai/grok-cli, the Grok-powered coding agent)
- **opencode**
- **pi** (lukasl-dev/pi.nix) — terminal-first agent

Each has a home-manager module under `modules/ai/<name>.nix`.

## Shared infrastructure (the key to DRY)

Two underscore modules provide single source of truth:

- `modules/ai/_agents.nix` — common agent definitions / settings.
- `modules/ai/_mcp.nix` — canonical MCP server list + serializers for each agent's config schema.

`common.nix` provides a `mempalace` wrapper script (using `uvx`) and pulls in `rtk` (Rust Token Killer, a token-saving proxy for Claude Code).

## MCP servers (centralized)

Defined once in `_mcp.nix`:

- `jcodemunch`
- `context-mode`
- `mempalace` (the memory palace MCP + CLI that complements this wiki)
- `sequential-thinking`
- `context7`

Each agent module imports the shared definition and translates it into the schema that agent expects (stdio for Claude Code, etc.).

Permissions / allow-lists are also managed per-agent (e.g. `mcp__mempalace__*`, `Bash(allowed commands:*)` etc.).

## Skills

Skills are loaded via the agent's extension/skill mechanism:

- `llm-wiki` (this very pattern — vendored at `modules/ai/skills/llm-wiki/SKILL.md`)
- `sensitive-files`

The skill files are passed as store paths (via `flake = false` inputs or direct paths) so no imperative install is needed.

See how `claude-code.nix`, `codex.nix`, `grok.nix`, `opencode.nix`, `pi.nix` consume skills (and for grok also sub-agents + MCPs) from the shared definitions.

## Why this matters (self-referentiality)

Because the agents can (and do) work inside this repository, and the repository defines how the agents are configured, we have a tight feedback loop:

- An agent using the `llm-wiki` skill can maintain the wiki that describes the agent provisioning.
- Changes to AI modules can be made by the agents themselves (with review).
- The same patterns used for "normal" modules apply to the AI modules.

This is why `ai-agents.md` exists as a first-class wiki page early in the bootstrap.

## MemPalace + llm-wiki

- **mempalace**: provides dynamic, partitioned working memory ("wings" and "rooms"). Configured at repo root by `mempalace.yaml` (currently one wing "dotfiles" with rooms for configuration, modules, overlays, pkgs, docs, general, etc.). Used via MCP by the agents for fast context.
- **llm-wiki** (this wiki): the slower, curated, synthesized, cross-linked, git-tracked knowledge base with history and rationale. Complements mempalace. The LLM writes the wiki; you browse it in Obsidian or via grep/agents.

Both are enabled for the main agents (with slight variation per tool).

## Configuration surface (high level)

For a new agent or major change, you typically touch:

1. The specific `<agent>.nix` (or add a new one following the pattern).
2. `_agents.nix` and/or `_mcp.nix` if shared behavior changes.
3. `common.nix` for common packages/wrappers.
4. The host wiring if a new group of users/hosts should get it.
5. Possibly flake inputs for new skills/plugins.
6. Update this wiki page + `modules.md` + any design docs.

Then `nix flake check` and deploy.

## Current gaps / evolution

- Some agents still have slightly different MCP/skill sets (documented in the pi design doc).
- Full parity and unified permission story is work in progress.
- The `karpathy-skills` and other upstream skill flakes are pulled in.

See the May 2026 pi module design doc for the most recent deep thinking on the shape.

## Using the agents with this wiki

When an agent has the llm-wiki skill loaded (it should be by default on machines using these modules), you can say:

- "Ingest the changes from the latest refactor into the wiki"
- "Lint the wiki for orphans and stale claims"
- "Query the wiki: how do groups compose with ai modules?"
- "Create a new page comparing the main agents"

The agent will read `wiki/index.md` + `wiki/schema.md` first, then do the right thing per the workflows defined in the schema.

This is the intended usage.
