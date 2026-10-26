{ inputs, ... }:
{
  flake.modules.homeManager.oh-my-pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ohMyPi = config.programs.omp.package;
      piIntercom = pkgs.pi-intercom;
      mcp = import ../_mcp.nix { inherit pkgs; };
      commonSkills = (import ../_skills.nix { inherit inputs pkgs; }).commonSkills;
      skillFiles = lib.listToAttrs (
        map (s: {
          name = ".omp/agent/skills/${s.name}";
          value = {
            source = s.src;
            recursive = true;
          };
        }) commonSkills
      );
      modelRoles = {
        default = "anthropic/claude-sonnet-5";
        smol = "anthropic/claude-haiku-4-5";
        slow = "anthropic/claude-opus-5";
      };

      fallbackChains = {
        default = [
          "openai-codex/gpt-6-luna"
          "xai-oauth/grok-4.6"
        ];
        smol = [
          "openai-codex/gpt-6-luna"
          "xai-oauth/grok-4.6"
        ];
        slow = [
          "openai-codex/gpt-6.1-sol"
          "xai-oauth/grok-4.6"
        ];
      };

      symbolPreset = "nerd";

      themeDark = "dark-catppuccin";

      memoryBackend = "mnemopi";
      mnemopiScoping = "per-project-tagged";

      cycleOrder = [
        "smol"
        "slow"
        "default"
      ];

    in
    {
      imports = [ inputs.oh-my-pi.homeManagerModules.default ];

      options.ryk.omp.broker.url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "http://hoid.local.ryk.sh:8765";
        description = ''
          Remote auth-broker this client resolves credentials through. Setting
          it bypasses the local SQLite credential store entirely: if the broker
          is unreachable at startup and the encrypted snapshot cache (1 h) has
          expired, OMP fails closed rather than falling back. The bearer token
          is read from `~/.omp/auth-broker.token`, which the host wires through
          sops — it is never written into the Nix store.
        '';
      };

      config = {
        # Enable the upstream module for the package only. Do not set
        # `programs.omp.settings` — that copies a generated YAML over
        # ~/.omp/agent/config.yml and wipes oauth / onboarding / runtime state.
        programs.omp.enable = true;

        home.file = {
          # Package root keeps pi-intercom's relative imports and manifest together.
          ".omp/agent/extensions/pi-intercom".source = piIntercom;
          ".omp/agent/skills/pi-intercom".source = "${piIntercom}/skills/pi-intercom";
          ".omp/agent/AGENTS.md".source = ./AGENTS.md;
          ".omp/agent/mcp.json".text = builtins.toJSON {
            mcpServers = mcp.toOhMyPi (mcp.pick [ "arcanum" ]);
          };
          # Escape stays free for autocomplete/modal dismissal; F9 is the
          # muscle-memory-safe cancel-turn chord for vim/helix users who
          # reach for Esc out of habit.
          ".omp/agent/keybindings.yml".text = builtins.toJSON {
            "app.interrupt" = "F9";
          };
        }
        // skillFiles;
        home.activation.ohMyPiModelConfiguration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${ohMyPi}/bin/omp config set modelRoles ${lib.escapeShellArg (builtins.toJSON modelRoles)}
          run ${ohMyPi}/bin/omp config set retry.fallbackChains ${lib.escapeShellArg (builtins.toJSON fallbackChains)}
          run ${ohMyPi}/bin/omp config set symbolPreset ${lib.escapeShellArg symbolPreset}
          run ${ohMyPi}/bin/omp config set theme.dark ${lib.escapeShellArg themeDark}
          run ${ohMyPi}/bin/omp config set memory.backend ${lib.escapeShellArg memoryBackend}
          run ${ohMyPi}/bin/omp config set mnemopi.scoping ${lib.escapeShellArg mnemopiScoping}
          run ${ohMyPi}/bin/omp config set cycleOrder ${lib.escapeShellArg (builtins.toJSON cycleOrder)}
        '';

        home.activation.ohMyPiBroker = lib.mkIf (config.ryk.omp.broker.url != null) (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${ohMyPi}/bin/omp config set auth.broker.url ${lib.escapeShellArg config.ryk.omp.broker.url}
          ''
        );
      };
    };
}
