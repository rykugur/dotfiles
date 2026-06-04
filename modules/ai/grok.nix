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
    let
      cfg = config.programs.grok;

      # Compute the declarative settings once and write them to a store file.
      # This avoids embedding a huge JSON literal (with ' characters from prompts
      # like "Sanderson's") directly into the activation script, which would break
      # bash single-quoting and cause the activation-script.drv to fail to build.
      baseGrokSettings = mkGrokUserSettings pkgs;
      grokSettingsJson = pkgs.writeText "grok-nix-settings.json" (builtins.toJSON baseGrokSettings);

      # We ONLY ever touch sops (or reference config.sops) if the user has
      # explicitly given permission by setting programs.grok.apiKeySecret.
      # "do not ever run sops without permission."
      apiKeySecretName = cfg.apiKeySecret;
      hasGrokApiKeySecret =
        apiKeySecretName != null
        && (config ? sops && config.sops ? secrets && config.sops.secrets ? apiKeySecretName);
      grokApiKeySecretPath =
        if hasGrokApiKeySecret then config.sops.secrets.${apiKeySecretName}.path else null;

      grokPkg =
        if hasGrokApiKeySecret then
          pkgs.writeShellScriptBin "grok" ''
            if [ -z "''${GROK_API_KEY:-}" ] && [ -r "${grokApiKeySecretPath}" ]; then
              export GROK_API_KEY="$(cat "${grokApiKeySecretPath}")"
            fi
            exec ${pkgs.grok-cli}/bin/grok "$@"
          ''
        else
          pkgs.grok-cli;
    in
    {
      options.programs.grok = {
        apiKeySecret = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "grok-api-key";
          description = ''
            Name of a sops secret (declared under sops.secrets in your hm config)
            that holds your xAI Grok API key.

            Setting this is the explicit "permission" to involve sops for the key.
            When set we:
            - wrap `grok` to auto-export $GROK_API_KEY from the secret at runtime
              (if not already present in the environment)
            - have the activation also ensure the key ends up in
              ~/.grok/user-settings.json

            If left null (the default), we never touch sops. You can still provide
            the key via $GROK_API_KEY, `grok -k ...`, or the TUI login flow (the
            activation maintains mcp/subAgents/skills in the json but will not
            clobber an apiKey written by the TUI).
          '';
        };
      };

      config = {
        home.packages = [ grokPkg ];

        home.file = builtins.listToAttrs (
          map (skill: {
            name = ".agents/skills/${skill.name}/SKILL.md";
            value.source = "${skill.src}/SKILL.md";
          }) skills
        );

        # Declaratively manage ~/.grok/user-settings.json via activation (not home.file)
        # so that:
        # - mcp servers and subAgents (from our shared _mcp / _agents) are always present
        # - the file remains a normal writable file in $HOME (so TUI can update it)
        # - TUI login / OAuth flows (which save apiKey to the file) continue to work
        #
        # The sops integration (wrapper for env + injection to json) only activates
        # if you set programs.grok.apiKeySecret (the explicit permission to touch sops).
        # See the option description above.
        home.activation.grokUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          set -euo pipefail

          SETTINGS_FILE="$HOME/.grok/user-settings.json"
          mkdir -p -m 700 "$(dirname "$SETTINGS_FILE")"

          NIX_SETTINGS_FILE=${grokSettingsJson}

          if [ -f "$SETTINGS_FILE" ]; then
            # Merge: Nix declarative keys win for mcp/subAgents; other keys (apiKey, hooks, etc.)
            # from the live file are preserved.
            ${lib.getExe pkgs.jq} -s '
              (.[0] // {}) as $existing |
              .[1] as $nix |
              ($existing + $nix)
            ' "$SETTINGS_FILE" "$NIX_SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
          else
            cp "$NIX_SETTINGS_FILE" "$SETTINGS_FILE.tmp"
          fi

          # If programs.grok.apiKeySecret is set (explicit permission), inject/override
          # the key from the corresponding sops secret. We never reference sops otherwise.
          ${lib.optionalString (hasGrokApiKeySecret) ''
            SECRET_PATH="${grokApiKeySecretPath}"
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
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.grok = pkgs.grok-cli;
    };
}
