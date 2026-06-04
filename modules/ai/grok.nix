{ inputs, ... }:
let
  inherit (import ./_agents.nix) resolveAgents toGrokAgent;

  # grok (superagent-ai/grok-cli) uses ~/.agents/skills/ for user-level skills
  # (and project .agents/skills/). This matches the AGENTS.md-compatible location
  # also used by codex, so skills are shared automatically. Grok also supports
  # its own .grok/skills/ and AGENTS.md family for instructions.

  skills = [
    { name = "frontend-design"; src = "${inputs.skills-anthropic}/skills/frontend-design"; }
    { name = "web-design-guidelines"; src = "${inputs.skills-vercel}/skills/web-design-guidelines"; }
    { name = "karpathy-guidelines"; src = "${inputs.karpathy-skills}/skills/karpathy-guidelines"; }
    { name = "sensitive-files"; src = ./skills/sensitive-files; }
    { name = "llm-wiki"; src = ./skills/llm-wiki; }
  ];

  # Grok model names (see `grok models` output or xAI docs).
  # Tiers mirror the pattern used for other agents.
  tierModels = {
    reference = "grok-3";
    technical = "grok-4.3";
  };

  agentOverrides = { };

  agents = resolveAgents { inherit tierModels agentOverrides; };

  mkGrokUserSettings = pkgs:
    let
      mcp = import ./_mcp.nix { inherit pkgs; };
    in
    {
      mcp = {
        servers = mcp.toGrok (mcp.pick [
          "jcodemunch"
          "context-mode"
          "mempalace"
          "sequential-thinking"
          "context7"
        ]);
      };
      subAgents = map toGrokAgent agents;
      # Hooks can be used for policy enforcement (PreToolUse etc. can return exit 2 to block).
      # See grok-cli README for full schema. Example:
      # hooks = {
      #   PreToolUse = [
      #     { matcher = "bash"; hooks = [ { type = "command"; command = "echo 'hook'"; timeout = 5; } ]; }
      #   ];
      # };
    };
in
{
  flake.modules.homeManager.grok =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.grok-cli ];

      home.file =
        builtins.listToAttrs (
          map (skill: {
            name = ".agents/skills/${skill.name}/SKILL.md";
            value.source = "${skill.src}/SKILL.md";
          }) skills
        )
        // {
          # Global user settings for MCP servers (shared) and custom sub-agents (from _agents.nix).
          # API key is best provided via $GROK_API_KEY or set manually in this file (avoid committing secrets).
          ".grok/user-settings.json".text = builtins.toJSON (mkGrokUserSettings pkgs);
        };

      # Expose the stock package for convenience (e.g. nix build .#grok or in dev shells).
      # No wrapper needed today (config lives in ~/.grok/ and is managed by home.file).
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.grok = pkgs.grok-cli;
    };
}
