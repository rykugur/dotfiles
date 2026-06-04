{ inputs, ... }:
let
  inherit (import ./_agents.nix) resolveAgents toGrokAgent;

  # grok (superagent-ai/grok-cli) uses ~/.agents/skills/ for user-level skills
  # (and project .agents/skills/). This matches the AGENTS.md-compatible location
  # also used by codex, so skills are shared automatically. Grok also supports
  # its own .grok/skills/ and AGENTS.md family for instructions.
  #
  # Project-level state (model prefs, sessions, etc.) goes in .grok/ in the cwd.
  # This directory is intentionally gitignored (see top-level .gitignore).

  skills = [
    { name = "frontend-design"; src = "${inputs.skills-anthropic}/skills/frontend-design"; }
    { name = "web-design-guidelines"; src = "${inputs.skills-vercel}/skills/web-design-guidelines"; }
    { name = "karpathy-guidelines"; src = "${inputs.karpathy-skills}/skills/karpathy-guidelines"; }
    { name = "sensitive-files"; src = ./skills/sensitive-files; }
    { name = "llm-wiki"; src = ./skills/llm-wiki; }
  ];

  # Model names for the sub-agents (see `grok models` for current list).
  # We pin a model per sub-agent so "reference" agents (lore, naming, etc.)
  # can be fast/cheap while "technical" ones are smarter. This is intentional
  # for consistent behavior across the custom agents.
  #
  # Note: these can get stale as xAI releases new models (grok-4, grok-3,
  # etc. and their -latest aliases). Update as needed. Per-invocation
  # --model may affect the main agent but sub-agents use their declared model.
  tierModels = {
    reference = "grok-3";
    technical = "grok-4";
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
    { config, lib, pkgs, ... }:
    let
      # Compute the declarative settings once and write them to a store file.
      # This avoids embedding a huge JSON literal (with ' characters from prompts
      # like "Sanderson's") directly into the activation script, which would break
      # bash single-quoting and cause the activation-script.drv to fail to build.
      baseGrokSettings = mkGrokUserSettings pkgs;
      grokSettingsJson = pkgs.writeText "grok-nix-settings.json" (builtins.toJSON baseGrokSettings);
    in
    {
      home.packages = [ pkgs.grok-cli ];

      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".agents/skills/${skill.name}/SKILL.md";
          value.source = "${skill.src}/SKILL.md";
        }) skills
      );

      # Declaratively manage ~/.grok/user-settings.json via activation (not home.file)
      # so that mcp servers and subAgents (from our shared _mcp / _agents) are
      # always present for the harness.
      #
      # We *only update* the file if it already exists (i.e. the user has
      # completed the TUI login flow at least once, which creates the file and
      # writes the apiKey via its OAuth/SSO flow). This prevents us from
      # pre-creating a keyless version that would cause the "API key required"
      # error on first run after a delete or fresh setup.
      #
      # The merge preserves any apiKey (and other keys like hooks) the TUI wrote.
      # If the file is absent, we do nothing — the TUI login flow can create it
      # with the key.
      #
      # Once the file exists (with your key), future switches will keep the
      # declarative mcp + subAgents fresh without clobbering the key.
      home.activation.grokUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        SETTINGS_FILE="$HOME/.grok/user-settings.json"

        if [ -f "$SETTINGS_FILE" ]; then
          mkdir -p -m 700 "$(dirname "$SETTINGS_FILE")"
          NIX_SETTINGS_FILE=${grokSettingsJson}
          ${lib.getExe pkgs.jq} -s '
            (.[0] // {}) as $existing |
            .[1] as $nix |
            ($existing + $nix)
          ' "$SETTINGS_FILE" "$NIX_SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
          mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
          chmod 600 "$SETTINGS_FILE" || true
        fi
      '';

      # Expose the stock package for convenience (e.g. nix build .#grok or in dev shells).
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.grok = pkgs.grok-cli;
    };
}
