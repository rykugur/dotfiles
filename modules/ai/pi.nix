{ inputs, ... }:
let
  # Extensions wired declaratively as flake-input source paths. Pi loads each
  # via Node-style module resolution from these paths.
  #
  # Only pi-subagents loads cleanly this way: its runtime deps (`@earendil-
  # works/*`, `jiti`, `typebox`) are all provided by pi's bundled module
  # graph.
  #
  # pi-mcp-adapter, pi-lens, and pi-permission-system each need real npm
  # `node_modules/` populated (for `@modelcontextprotocol/sdk`, `vscode-
  # jsonrpc`, `jsonc-parser`, etc.). Building those with `pkgs.buildNpmPackage`
  # turned into a tar pit (peer-dep handling + lockfile inconsistencies). For
  # now we install them imperatively via `pi install npm:<name>` in the
  # activation script below. Pi auto-discovers `~/.pi/agent/extensions/<name>/`
  # so no `--extension` flag is needed for those.
  declarativeExtensions = [
    inputs.pi-subagents
  ];

  # Extensions installed imperatively. Activation script runs `pi install`
  # for any that aren't already present in ~/.pi/agent/npm/node_modules/.
  imperativeExtensions = [
    "pi-mcp-adapter"
    "pi-lens"
    "pi-permission-system"
  ];

  skills = [
    {
      name = "frontend-design";
      src = "${inputs.skills-anthropic}/skills/frontend-design";
    }
    {
      name = "web-design-guidelines";
      src = "${inputs.skills-vercel}/skills/web-design-guidelines";
    }
    {
      name = "karpathy-guidelines";
      src = "${inputs.karpathy-skills}/skills/karpathy-guidelines";
    }
    {
      name = "sensitive-files";
      src = ./skills/sensitive-files;
    }
  ];

  mkPiMcpConfig =
    pkgs:
    let
      mcp = import ./_mcp.nix { inherit pkgs; };
    in
    {
      mcpServers = mcp.toPi (mcp.pick [
        "jcodemunch"
        "context-mode"
        "mempalace"
        "sequential-thinking"
        "context7"
      ]);
    };

  # pi-permission-system schema (per MasuRii/pi-permission-system README):
  #   - defaultPolicy is an object keyed by category, not a single string.
  #   - MCP wildcards use underscore-separated server/tool names (e.g.
  #     "jcodemunch_*"), matching opencode's convention.
  #   - File-path patterns (e.g. *.env, *.sops.yaml) have no direct equivalent
  #     here: `special.external_directory` only guards out-of-cwd paths, and
  #     `tools.read` is binary (no glob support). The `sensitive-files` skill
  #     in the skills list above is the soft-enforcement substitute.
  piPermissionsPolicy = {
    defaultPolicy = {
      tools = "allow";
      bash = "allow";
      mcp = "allow";
      skills = "allow";
      special = "ask";
    };

    bash = {
      "*" = "allow";
      "rm *" = "deny";
      "npm *" = "deny";
      "kubectl get *" = "allow";
      "kubectl logs *" = "allow";
      "flux get *" = "allow";
    };

    mcp = {
      "jcodemunch_*" = "allow";
      "context7_*" = "allow";
      "context-mode_ctx_*" = "allow";
      "mempalace_*" = "allow";
      "sequential-thinking_*" = "allow";
    };

    skills = {
      "frontend-design" = "allow";
      "web-design-guidelines" = "allow";
      "karpathy-guidelines" = "allow";
      "sensitive-files" = "allow";
    };

    special = {
      external_directory = "ask";
    };
  };
in
{
  flake.modules.homeManager.pi =
    { config, pkgs, ... }:
    {
      imports = [ inputs.pi.homeModules.default ];

      programs.pi.coding-agent = {
        enable = true;
        extensions = declarativeExtensions;
        skills = map (s: s.src) skills;
      };

      home.file.".pi/agent/mcp.json".text = builtins.toJSON (mkPiMcpConfig pkgs);
      home.file.".pi/agent/pi-permissions.jsonc".text = builtins.toJSON piPermissionsPolicy;

      home.activation.installPiExtensions = ''
        export PATH="${config.programs.pi.coding-agent.finalPackage}/bin:$PATH"
        ${pkgs.lib.concatMapStringsSep "\n" (name: ''
          if [ ! -d "$HOME/.pi/agent/npm/node_modules/${name}" ]; then
            echo "Installing pi extension: ${name}"
            pi install "npm:${name}" || echo "  warn: pi install ${name} failed"
          fi
        '') imperativeExtensions}
      '';
    };
}
