---
title: AI Agents
category: ai
date: 2026-10-13
tags: [ai, agents, claude-code, codex, grok, opencode, oh-my-pi, herdr, herdr-navigator, hermes, vasher, openrig, mempalace, llm-wiki, skills, mcp]
sources: ["modules/ai/", "modules/ai/_agents.nix", "modules/ai/_mcp.nix", "modules/ai/_skills.nix", "modules/ai/claude-code.nix", "modules/ai/grok.nix", "modules/ai/herdr.nix", "modules/ai/oh-my-pi/default.nix", "modules/ai/common.nix", "modules/ai/vasher-supervisor.nix", "modules/ai/vasher-supervise.sh", "modules/ai/skills/vasher-supervisor/SKILL.md", "modules/ai/skills/llm-wiki/SKILL.md", "pkgs/herdr-navigator.nix", "pkgs/openrig.nix", "flake.nix"]
related: ["overview.md", "architecture.md", "modules.md"]
---

# AI Agents

One of the most distinctive parts of Swoleflake is that AI coding agents are treated as **first-class, declaratively managed software** — exactly like shells, editors, or window managers.

The goal: identical (or as close as the host allows) agent experience on every machine, installed and configured purely through Nix, with no imperative `claude install ...` steps that leave state in `~/.claude/`.

## The agents

- **claude-code** (Anthropic's Claude Code)
- **codex** (OpenAI Codex / successor agent)
- **grok** (superagent-ai/grok-cli, the Grok-powered coding agent; uses `~/.agents/skills/` (declarative via module) + `.grok/` (project state, gitignored) + `~/.grok/user-settings.json` (TUI-managed for API key etc.))
- **opencode**
- **oh-my-pi** (OMP, `can1357/oh-my-pi`) — terminal-first agent; the one actually used day-to-day (config at `~/.omp/agent/`)

Note: `lukasl-dev/pi.nix` was evaluated (see the May 2026 pi module design doc) but never wired into any host and was removed — OMP is the only terminal agent in active use.

Each has a home-manager module under `modules/ai/<name>.nix`.

## Agent orchestration

**OpenRig** is installed declaratively through `ai-common` on Jezrien and Taln. The local `pkgs.openrig` derivation pins the published `@openrig/cli` npm artifact and its dependency closure, uses Node.js 22, exposes `rig` and `openrig-tui`, and supplies `tmux` on their runtime `PATH`. Installation does not run `rig setup`, start the daemon, or create OpenRig state during Home Manager activation.

**Herdr** is the shared terminal workspace runtime on Jezrien and Taln. Its
Home Manager module owns tab and pane navigation and installs the OMP lifecycle
integration. The local `pkgs.herdr-navigator` package builds version 0.3.3
reproducibly; activation links its immutable plugin root into Herdr, while
`prefix+t` opens its cross-workspace picker. `Alt+H/L` switches tabs;
`Alt+Shift+H/L` reorders them. `Ctrl+Shift+H/J/K/L` focuses panes left/down/up/right.
Prefix fallbacks remain for tab switching, tab movement, and pane focus.
Herdr's implicit Catppuccin default is named explicitly so Navigator's theme
inheritance selects its matching Catppuccin Mocha palette.

The [Ghostty module](../modules/terminal/ghostty.nix) checks
`config.programs.herdr.enable or false`: Herdr-enabled homes release Ghostty's
split-navigation chords and unbind its Linux `Ctrl+Shift+J` default. Homes without
Herdr retain the four original Ghostty split shortcuts. All Ghostty homes get a
`Fav: Paste screen path` palette alias, using the expanded action fields accepted
by Ghostty 1.3.1; default palette entries remain available. Helix bindings are
unchanged. See the [Herdr module](../modules/ai/herdr.nix) for the full key lists.
Nix evaluation and activation are deferred to the Linux machine; neither ran
during this configuration edit.

**Oh My Pi** comes from the official `can1357/oh-my-pi` flake via
`programs.omp.enable`. The local Home Manager module still owns `AGENTS.md`,
MCP, skills, shell completions, and `omp config set` for model roles / theme /
mnemopi. `programs.omp.settings` is intentionally unset: upstream copies a
generated YAML over `~/.omp/agent/config.yml` and would wipe oauth and
runtime state.

## Vasher supervisor

The Home Manager module `flake.modules.homeManager.vasher-supervisor` installs the `vasher-supervise` wrapper and its user services and timers on Jezrien. Shared module `modules/ai/_skills.nix` installs the `vasher-supervisor` skill. The regular timer runs every 30 minutes and skips the Monday 09:00 weekly digest slot.

Healthy polls make zero model calls. The wrapper observes the read-only `/api/status.json`, `/api/events.json`, and `/api/agent-events.json` endpoints. Actions require a dedicated public key in `ryk.vasherPrebuild.agentKeys` and its private key at `~/.ssh/vasher-agent`. Without this key pair, supervision stays read-only.

## Shared infrastructure (the key to DRY)

Two underscore modules provide single source of truth:

- `modules/ai/_agents.nix` — common agent definitions / settings.
- `modules/ai/_mcp.nix` — canonical MCP server list + serializers for each agent's config schema.

`common.nix` provides a `mempalace` wrapper script and installs `rtk`, `llmfit`, and the locally packaged OpenRig CLI.

## MCP servers (centralized)

Defined once in `_mcp.nix`:

- `jcodemunch`
- `context-mode`
- `mempalace` (the memory palace MCP + CLI that complements this wiki)
- `context7`

Each agent module imports the shared definition and translates it into the schema that agent expects (stdio for Claude Code, etc.).

Permissions / allow-lists are also managed per-agent (e.g. `mcp__mempalace__*`, `Bash(allowed commands:*)` etc.).

## Skills

Skills are loaded via the agent's extension/skill mechanism:

- `llm-wiki` (this very pattern — vendored at `modules/ai/skills/llm-wiki/SKILL.md`)
- `sensitive-files`
- Superpowers skills (https://github.com/obra/superpowers) — the full TDD / planning / subagent / review methodology. Installed wholesale for `.agents/skills/` consumers (codex, grok) via `_skills.nix`; loaded as plugins for claude-code and opencode.
- Herdr's official `herdr` skill, sourced directly from the configured Herdr package, teaches agents to operate Herdr only when running in a Herdr-managed pane. Package and skill therefore update in lockstep.

The skill files (and companion assets) are passed as store paths (via `flake = false` inputs or direct paths) so no imperative install is needed. For superpowers we symlink entire skill dirs so extra docs are present.

See how `claude-code.nix`, `codex.nix`, `grok.nix`, `opencode.nix`, `oh-my-pi/default.nix`, and `herdr.nix` consume or extend the shared skill infrastructure. `_skills.nix` is the central skill registry.

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

- Some agents still have slightly different MCP/skill sets.
- Full parity and unified permission story is work in progress.
- The `karpathy-skills` and other upstream skill flakes are pulled in.

## Using the agents with this wiki

When an agent has the llm-wiki skill loaded (it should be by default on machines using these modules), you can say:

- "Ingest the changes from the latest refactor into the wiki"
- "Lint the wiki for orphans and stale claims"
- "Query the wiki: how do groups compose with ai modules?"
- "Create a new page comparing the main agents"

The agent will read `wiki/index.md` + `wiki/schema.md` first, then do the right thing per the workflows defined in the schema.

This is the intended usage.
