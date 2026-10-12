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
          "openai-codex/gpt-5.6-terra"
          "xai-oauth/grok-4.6"
          "openrouter/deepseek/deepseek-v4-flash-0731"
        ];
        smol = [
          "openai-codex/gpt-5.6-luna"
          "xai-oauth/grok-4.6"
          "openrouter/deepseek/deepseek-v4-flash-0731"
        ];
        slow = [
          "openai-codex/gpt-5.6-sol"
          "xai-oauth/grok-4.6"
          "openrouter/deepseek/deepseek-v4-flash-0731"
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

      mkCompletion =
        shell:
        pkgs.runCommand "omp-${shell}-completion" { nativeBuildInputs = [ ohMyPi ]; } ''
          export HOME="$TMPDIR"
          omp completions ${shell} > "$out"
        '';
    in
    {
      imports = [ inputs.oh-my-pi.homeManagerModules.default ];

      config = lib.mkMerge [
        {
          # Enable the upstream module for the package only. Do not set
          # `programs.omp.settings` — that copies a generated YAML over
          # ~/.omp/agent/config.yml and wipes oauth / onboarding / runtime state.
          programs.omp.enable = true;

          home.file = {
            ".omp/agent/AGENTS.md".source = ./AGENTS.md;
            ".omp/agent/mcp.json".text = builtins.toJSON {
              mcpServers = mcp.toOhMyPi (mcp.pick [ "arcanum" ]);
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
        }

        (lib.mkIf (config.ryk.defaultShell == "fish") {
          xdg.configFile."fish/completions/omp.fish".source = mkCompletion "fish";
        })

        (lib.mkIf (config.ryk.defaultShell == "bash") {
          programs.bash = {
            enable = true;
            enableCompletion = true;
          };

          home.file.".local/share/bash-completion/completions/omp".source = mkCompletion "bash";
        })
      ];
    };
}
