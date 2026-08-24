{ inputs, ... }:
let
  # Hermes Agent (NousResearch/hermes-agent) uses ~/.hermes/skills/ for
  # skills — compatible with the agentskills.io standard, same progressive-
  # disclosure SKILL.md format used elsewhere. Installed via the shared
  # .agents-style skill set (includes superpowers) same as codex/grok/pi.
  inherit ((import ./_skills.nix { inherit inputs; })) skillsForDotAgents;
  skills = skillsForDotAgents;

  mkHermesMcpConfig =
    pkgs:
    let
      mcp = import ./_mcp.nix { inherit pkgs; };
    in
    mcp.toHermes (mcp.pick [
      "jcodemunch"
      "context-mode"
      "context7"
    ]);
in
{
  flake.modules.homeManager.hermes-agent =
    { config, lib, pkgs, ... }:
    let
      mcpServersFile = pkgs.writeText "hermes-mcp-servers.yaml" (
        lib.generators.toYAML { } { mcp_servers = mkHermesMcpConfig pkgs; }
      );
    in
    {
      home.packages = [ inputs.hermes-agent.packages.${pkgs.system}.default ];

      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".hermes/skills/${skill.name}";
          value.source = skill.src;
        }) skills
      );

      # There's no home-manager equivalent of the upstream NixOS module's
      # declarative `settings` merge (that logic lives in the NixOS module
      # only). We're not running the NixOS service here — just the CLI, same
      # as claude-code/opencode/codex/grok/pi — so config.yaml is otherwise
      # managed imperatively via `hermes setup`. Replicate the NixOS module's
      # documented merge semantics for just the mcp_servers key: Nix-declared
      # servers win, everything else already on disk (model prefs, auth,
      # other manually-added servers) is preserved. Mirrors the rtk
      # --auto-patch pattern in common.nix.
      home.activation.hermesAgentMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        configDir="${config.home.homeDirectory}/.hermes"
        configFile="$configDir/config.yaml"
        run mkdir -p "$configDir"
        if [ ! -s "$configFile" ]; then
          run ${pkgs.coreutils}/bin/tee "$configFile" <<< "{}" >/dev/null
        fi
        run ${pkgs.yq-go}/bin/yq eval-all -i \
          'select(fileIndex==0) * select(fileIndex==1)' \
          "$configFile" "${mcpServersFile}"
      '';
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.hermes-agent = inputs.hermes-agent.packages.${pkgs.system}.default;
    };
}
