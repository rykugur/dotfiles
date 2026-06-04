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
      # so that:
      # - mcp servers and subAgents (from our shared _mcp / _agents) are always present
      # - the file remains a normal writable file in $HOME (so the TUI login flow
      #   can write the apiKey via OAuth/SSO and it will persist)
      #
      # We never touch apiKey ourselves (no sops, no wrapper, no forcing). The
      # merge below always preserves any existing "apiKey" (or other user-managed
      # keys like hooks) from the live file. If the file doesn't exist yet, we
      # create it with just the declarative bits; the TUI can then do its login
      # and save the key.
      #
      # To initially obtain a key via TUI: just run `grok` (it will guide you
      # through the login flow that uses OAuth/SSO and persist the key).
      # Subsequent runs will find it. Our activation will keep mcp/subAgents
      # fresh without clobbering the key.
      home.activation.grokUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        SETTINGS_FILE="$HOME/.grok/user-settings.json"
        mkdir -p -m 700 "$(dirname "$SETTINGS_FILE")"

        NIX_SETTINGS_FILE=${grokSettingsJson}

        if [ -f "$SETTINGS_FILE" ]; then
          # Merge our declarative bits over whatever is there. This keeps any
          # apiKey (or other keys) that the TUI login flow wrote.
          ${lib.getExe pkgs.jq} -s '
            (.[0] // {}) as $existing |
            .[1] as $nix |
            ($existing + $nix)
          ' "$SETTINGS_FILE" "$NIX_SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
        else
          cp "$NIX_SETTINGS_FILE" "$SETTINGS_FILE.tmp"
        fi

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
