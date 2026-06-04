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
    { config, lib, pkgs, ... }:
    {
      home.packages = [ pkgs.grok-cli ];

      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".agents/skills/${skill.name}/SKILL.md";
          value.source = "${skill.src}/SKILL.md";
        }) skills
      );

      # Declaratively manage ~/.grok/user-settings.json via activation (not home.file)
      # so that:
      # - mcp servers and subAgents (from our shared _mcp / _agents) are always present
      # - the file remains a normal writable file in $HOME
      # - TUI login / OAuth flows (which save apiKey to the file) continue to work
      # - apiKey can optionally come from a sops secret (see below)
      #
      # If you want to manage the API key declaratively with sops-nix, declare:
      #   sops.secrets.grok-api-key = { sopsFile = ./secrets.yaml; };
      # in your home-manager user config (alongside importing the sops module).
      # The key will be injected on activation. Env var $GROK_API_KEY always takes precedence at runtime.
      home.activation.grokUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        SETTINGS_FILE="$HOME/.grok/user-settings.json"
        mkdir -p -m 700 "$(dirname "$SETTINGS_FILE")"

        # Our declarative bits (MCP + custom sub-agents). Never include apiKey here
        # so we don't clobber TUI-saved keys unless a sops secret is configured.
        NIX_SETTINGS='${builtins.toJSON (mkGrokUserSettings pkgs)}'

        if [ -f "$SETTINGS_FILE" ]; then
          # Merge: Nix declarative keys win for mcp/subAgents; other keys (apiKey, hooks, etc.)
          # from the live file are preserved.
          ${lib.getExe pkgs.jq} -s '
            (.[0] // {}) as $existing |
            .[1] as $nix |
            ($existing + $nix)
          ' "$SETTINGS_FILE" <(printf '%s\n' "$NIX_SETTINGS") > "$SETTINGS_FILE.tmp"
        else
          printf '%s\n' "$NIX_SETTINGS" > "$SETTINGS_FILE.tmp"
        fi

        # If a sops secret named "grok-api-key" is configured for this user, inject/override it.
        # This is safe even if the sops module isn't imported (the optionalString becomes a no-op).
        ${lib.optionalString (config ? sops && config.sops ? secrets && config.sops.secrets ? "grok-api-key") ''
          SECRET_PATH="${config.sops.secrets."grok-api-key".path}"
          if [ -r "$SECRET_PATH" ]; then
            API_KEY=$(cat "$SECRET_PATH")
            ${lib.getExe pkgs.jq} --arg apiKey "$API_KEY" '
              . + {apiKey: $apiKey}
            ' "$SETTINGS_FILE.tmp" > "$SETTINGS_FILE.tmp2"
            mv "$SETTINGS_FILE.tmp2" "$SETTINGS_FILE.tmp"
          fi
        ''}

        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        chmod 600 "$SETTINGS_FILE" || true
      '';

      # Expose the stock package for convenience (e.g. nix build .#grok or in dev shells).
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.grok = pkgs.grok-cli;
    };
}
