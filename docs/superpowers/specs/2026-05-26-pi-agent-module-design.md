# Pi Coding Agent Module + Shared MCP Definitions

## Problem

Two related goals in one design:

1. **Add a `pi` agent module.** Pi (lukasl-dev/pi.nix) is a terminal coding agent we want to manage with the same declarative, cross-machine guarantees as `claude-code`, `opencode`, and `codex`. Upstream's intended workflow is imperative (`pi install npm:<ext>`) which leaves mutable state in `~/.pi/`. We need a `modules/ai/pi.nix` that wires the agent, four extensions, three skills, MCP servers, and a permission policy purely through Nix.

2. **Centralize MCP server definitions.** `claude-code.nix`, `opencode.nix`, and the new `pi.nix` would each define the same five MCP servers (`jcodemunch`, `context-mode`, `mempalace`, `sequential-thinking`, `context7`) in three different schemas. Single source of truth via `modules/ai/_mcp.nix`, mirroring the `_agents.nix` pattern.

Pi extensions and skills are loaded via repeated `--extension` / `--skill` CLI flags. `pi.nix`'s home-manager module already accepts `listOf path` for both, so each extension can be a `flake = false` input and passed by store path — no `pi install` required.

## Design

### Shared MCP definitions (`modules/ai/_mcp.nix`)

Underscore prefix prevents `import-tree` auto-discovery. Imported manually by each agent module, same pattern as `_agents.nix`.

Exports canonical server definitions plus per-tool serializers. The canonical form is `{ command, args, env? }` — what most MCP runtimes expect; pi consumes this directly. Claude Code and Opencode each have their own schema, so we provide explicit translators.

```nix
{ pkgs }:
let
  inherit (pkgs) lib;

  servers = {
    jcodemunch = {
      command = "${pkgs.uv}/bin/uvx";
      args    = [ "--python" "3.13" "jcodemunch-mcp" ];
    };
    context-mode = {
      command = "${pkgs.nodejs}/bin/npx";
      args    = [ "-y" "context-mode" ];
      env     = { PATH = "${pkgs.nodejs}/bin:${pkgs.coreutils}/bin:/bin:/usr/bin"; };
    };
    mempalace = {
      command = "${pkgs.uv}/bin/uv";
      args    = [ "run" "--with" "mempalace" "--python" "3.13"
                  "python" "-m" "mempalace.mcp_server" ];
    };
    sequential-thinking = {
      command = "${pkgs.bun}/bin/bunx";
      args    = [ "@modelcontextprotocol/server-sequential-thinking" ];
    };
    context7 = {
      command = "${pkgs.bun}/bin/bunx";
      args    = [ "@upstash/context7-mcp" ];
    };
  };

  pick = names: lib.getAttrs names servers;

  # Claude Code: { type = "stdio"; command; args; env?; }
  toClaudeCode = serverSet: lib.mapAttrs (_: s:
    { type = "stdio"; inherit (s) command args; }
    // lib.optionalAttrs (s ? env) { inherit (s) env; }
  ) serverSet;

  # Opencode: { type = "local"; command = [cmd args...]; environment?; }
  toOpencode = serverSet: lib.mapAttrs (_: s:
    { type = "local"; command = [ s.command ] ++ s.args; }
    // lib.optionalAttrs (s ? env) { environment = s.env; }
  ) serverSet;

  # Pi: canonical form unchanged
  toPi = serverSet: serverSet;
in
{
  inherit servers pick toClaudeCode toOpencode toPi;
}
```

Call sites:

```nix
# claude-code.nix
mkClaudeCodeMcpConfig = pkgs:
  let m = import ./_mcp.nix { inherit pkgs; };
  in m.toClaudeCode (m.pick [
    "jcodemunch" "context-mode" "mempalace" "sequential-thinking"
  ]);

# opencode.nix (inside mkOpencodeSettings)
mcp = let m = import ./_mcp.nix { inherit pkgs; };
      in m.toOpencode (m.pick [
        "jcodemunch" "context-mode" "sequential-thinking" "context7"
      ]);

# pi.nix
mkPiMcpConfig = pkgs:
  let m = import ./_mcp.nix { inherit pkgs; };
  in { mcpServers = m.toPi (m.pick [
    "jcodemunch" "context-mode" "mempalace" "sequential-thinking" "context7"
  ]); };
```

**Out of scope for `_mcp.nix`:** the `context7` plugin patching in `claude-code.nix:92-105` stays as-is. That uses Claude Code's plugin-loading mechanism (a directory with its own `.mcp.json`), not the per-tool MCP config — different surface, different concern.

### Flake inputs (`flake.nix`)

Added to the `### ai stuff` section:

```nix
pi = {
  url = "github:lukasl-dev/pi.nix";
  inputs.nixpkgs.follows = "nixpkgs";
};

pi-subagents = {
  url = "github:nicobailon/pi-subagents";
  flake = false;
};
pi-mcp-adapter = {
  url = "github:nicobailon/pi-mcp-adapter";
  flake = false;
};
pi-lens = {
  url = "github:apmantza/pi-lens";
  flake = false;
};
pi-permission-system = {
  url = "github:MasuRii/pi-permission-system";
  flake = false;
};
```

Appended to the existing `nixConfig.extra-substituters` / `extra-trusted-public-keys` lists in `flake.nix`:

```
"https://pi.cachix.org"
"pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
```

### Module shape (`modules/ai/pi.nix`)

Single home-manager module. Imports `inputs.pi.homeModules.default` and configures `programs.pi.coding-agent`:

```nix
{ inputs, ... }:
let
  extensions = [
    inputs.pi-subagents
    inputs.pi-mcp-adapter
    inputs.pi-lens
    inputs.pi-permission-system
  ];

  skills = [
    { name = "frontend-design";        src = "${inputs.skills-anthropic}/skills/frontend-design"; }
    { name = "web-design-guidelines";  src = "${inputs.skills-vercel}/skills/web-design-guidelines"; }
    { name = "karpathy-guidelines";    src = "${inputs.karpathy-skills}/skills/karpathy-guidelines"; }
  ];

  mkPiMcpConfig = pkgs: { … };   # see "MCP config" below
  piPermissionsPolicy = { … };   # see "Permission policy" below
in
{
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    {
      imports = [ inputs.pi.homeModules.default ];

      programs.pi.coding-agent = {
        enable     = true;
        extensions = extensions;
        skills     = map (s: s.src) skills;
      };

      home.file.".pi/agent/mcp.json".text =
        builtins.toJSON (mkPiMcpConfig pkgs);

      home.file.".pi/agent/pi-permissions.jsonc".text =
        builtins.toJSON piPermissionsPolicy;
    };
}
```

`{ name; src; }` skill shape is preserved for parity with `claude-code.nix` and `opencode.nix` even though pi only needs `src`.

### MCP config

Sourced from `_mcp.nix` via `toPi (pick [...])`. Written to `~/.pi/agent/mcp.json` (pi-scoped, not the shared `~/.config/mcp/mcp.json`). Includes all five servers; `pi-mcp-adapter` lazy-loads each (~200 token idle cost per server, only connects when invoked), so this set is cheap.

### Permission policy

Written to `~/.pi/agent/pi-permissions.jsonc`. Ports `modules/ai/opencode.nix:38-69` into MasuRii's schema.

**Note for implementation:** the exact wildcard syntax for MCP entries (e.g. `jcodemunch.*` vs `jcodemunch_*` vs `jcodemunch/tool-name`) and the precise top-level keys (`bash`, `mcp`, `skills`, `special.read` vs alternative spellings) should be verified against `pi-permission-system`'s README/schema during implementation. The structure below is what MasuRii's docs describe; treat the exact key names as a starting point, not gospel.

```nix
piPermissionsPolicy = {
  defaultPolicy = "allow";

  bash = {
    "*"            = "allow";
    "rm *"         = "deny";
    "npm *"        = "deny";
    "kubectl get *" = "allow";
    "kubectl logs *" = "allow";
    "flux get *"   = "allow";
  };

  mcp = {
    "jcodemunch.*"          = "allow";
    "context7.*"            = "allow";
    "context-mode.ctx_*"    = "allow";
    "mempalace.*"           = "allow";
    "sequential-thinking.*" = "allow";
  };

  skills = {
    "frontend-design"       = "allow";
    "web-design-guidelines" = "allow";
    "karpathy-guidelines"   = "allow";
  };

  special = {
    read = {
      "*"             = "allow";
      "*.env"         = "deny";
      "*.env.*"       = "deny";
      ".envrc"        = "deny";
      "*.sops.yaml"   = "deny";
      "*.tfvars"      = "deny";
      "*.env.example" = "allow";
    };
  };
};
```

### Host wiring

Add `pi` to the home-manager `imports` list in:

- `modules/hosts/taln/default.nix` — alongside `claude-code`, `opencode`, `codex`
- `modules/hosts/jezrien/default.nix` — same pattern

### Implementation order

To keep the diff reviewable:

1. Land `_mcp.nix` and refactor `claude-code.nix` + `opencode.nix` to consume it. Behavior unchanged — `nix flake check` should pass and the rendered MCP config should be byte-identical (modulo attr ordering).
2. Add the flake inputs (`pi`, `pi-subagents`, `pi-mcp-adapter`, `pi-lens`, `pi-permission-system`) and cachix substituter.
3. Add `modules/ai/pi.nix` using `_mcp.nix` from the start.
4. Wire `pi` into `modules/hosts/taln/default.nix` and `modules/hosts/jezrien/default.nix`.

### What this does NOT cover

- A `perSystem.packages.pi` output. `pi.nix`'s home module installs the binary directly; we don't need to re-expose it.
- Custom pi-subagents definitions. Pi-subagents ships built-in roles (scout, researcher, planner, worker, reviewer, oracle); we use those.
- A `pi-yolo` shell-script variant (analogous to `opencode-yolo`). Can be added later if desired.
- The optional pi-subagents companions (`pi-web-access`, `pi-intercom`). Add if/when needed.
- Migrating the `context7` plugin in `claude-code.nix` from the plugin-dir mechanism to the standard MCP config. Different surface, different concern.

## Principles

- **Declarative over imperative** — no `pi install` runs; all extensions are flake inputs at `flake = false`, loaded via `--extension` flags.
- **Reuse upstream** — `pi.nix` already exposes a home-manager module that wraps the binary; we configure it, not re-wrap it.
- **Consistency with existing AI modules** — same skill list shape, same MCP server set, same permission philosophy as `opencode.nix`.
- **Cachix opt-in via `nixConfig`** — matches how `hyprland`, `nix-gaming`, etc. are wired.
