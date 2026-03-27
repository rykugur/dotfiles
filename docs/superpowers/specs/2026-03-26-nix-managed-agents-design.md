# Nix-Managed Agents: Cross-Tool Agent Definitions via Home-Manager

## Problem

Claude Code and opencode both support custom agents (markdown files with YAML frontmatter), but they use different schemas and different file locations. Defining agents manually in each tool's format means duplication, drift, and no way to distribute them across machines via the dotfiles flake.

## Design

### Shared agent definitions in `modules/ai/_agents.nix`

A Nix file exporting a list of agent attrsets with tool-agnostic fields. Imported manually by `claude-code.nix` and `opencode.nix` (underscore prefix prevents `import-tree` auto-discovery), same pattern as `_shared.nix`.

Each agent definition:

```nix
{
  name = "cosmere";
  description = "Cosmere universe specialist. Use when naming projects, generating quotes, answering questions about Brandon Sanderson's Cosmere universe, or when the user asks for thematic inspiration.";
  model = "sonnet";
  mode = "reference"; # "reference" = read-only tools, "technical" = full tool access
  prompt = ''
    You are an expert on Brandon Sanderson's Cosmere universe...
  '';
}
```

Fields:
- **name** — kebab-case identifier, becomes the filename
- **description** — tells the AI when to auto-delegate; also shown in agent listings
- **model** — `"sonnet"`, `"haiku"`, `"opus"`, or a full model ID
- **mode** — `"reference"` restricts to read-only tools, `"technical"` inherits all tools
- **prompt** — the agent's system prompt (markdown body)

### Generator functions

Two functions in `_agents.nix` convert agent definitions to the correct markdown format:

**`toClaudeCodeAgent`** — produces markdown for `~/.claude/agents/<name>.md`:
```markdown
---
description: Cosmere universe specialist...
model: sonnet
tools: Read, Grep, Glob, WebFetch, WebSearch
---

You are an expert on Brandon Sanderson's Cosmere universe...
```

Note: Claude Code derives the agent name from the filename (`cosmere.md`), so no `name` field in frontmatter.

For `mode = "reference"`: `tools: Read, Grep, Glob, WebFetch, WebSearch` (no Bash — truly read-only)
For `mode = "technical"`: no `tools` field (inherits all)

**`toOpencodeAgent`** — produces markdown for `~/.config/opencode/agents/<name>.md`:
```markdown
---
description: Cosmere universe specialist...
mode: subagent
model: anthropic/claude-sonnet-4-20250514
tools:
  write: false
---

You are an expert on Brandon Sanderson's Cosmere universe...
```

For `mode = "reference"`: `tools: { write = false; }`
For `mode = "technical"`: `tools: { write = true; }`

Model mapping for opencode is defined as a standalone attrset in `_agents.nix` for easy updates when new models release:

```nix
opencodeModelMap = {
  sonnet = "anthropic/claude-sonnet-4-20250514";
  opus = "anthropic/claude-opus-4-20250514";
  haiku = "anthropic/claude-haiku-4-5-20251001";
};
```

Short names are looked up in this map. Full qualified model IDs (containing `/`) pass through unchanged.

### Home-manager integration

Each tool's module (`claude-code.nix`, `opencode.nix`) imports `_agents.nix` and uses the generator to create agent files:

**`claude-code.nix`** adds:
```nix
home.file = lib.listToAttrs (map (agent: {
  name = ".claude/agents/${agent.name}.md";
  value.text = toClaudeCodeAgent agent;
}) agents);
```

**`opencode.nix`** adds:
```nix
xdg.configFile = lib.listToAttrs (map (agent: {
  name = "opencode/agents/${agent.name}.md";
  value.text = toOpencodeAgent agent;
}) agents);
```

### Starting agent set

| Name | Mode | Description |
|------|------|-------------|
| `cosmere` | reference | Brandon Sanderson's Cosmere universe — naming, quotes, lore |
| `red-rising` | reference | Pierce Brown's Red Rising saga — naming, quotes, lore |
| `wheel-of-time` | reference | Robert Jordan's Wheel of Time — naming, quotes, lore |
| `cloud-native` | technical | Kubernetes, Flux, Helm, Proxmox, infrastructure |
| `nixos` | technical | NixOS, Nix language, home-manager, flakes |

### What this does NOT cover

- Hooks (pinned for future work)
- MCP server configuration (already handled by existing modules)
- Agent-to-agent delegation (not supported by Claude Code)

## Principles

- **Single source of truth** — one definition, two outputs
- **Same pattern as `_shared.nix`** — underscore prefix, manual import
- **Reference agents are read-only** — no file editing for fantasy lore agents
- **Technical agents inherit all tools** — full access for infra/nix work
