{ inputs, ... }:
let
  extensions = [
    inputs.pi-subagents
    inputs.pi-mcp-adapter
    inputs.pi-lens
    inputs.pi-permission-system
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
  #   - File-path patterns (e.g. *.env, *.sops.yaml) from opencode's read
  #     section have no direct equivalent here: special.external_directory
  #     only guards OUT-OF-cwd paths. Sensitive files inside cwd are not
  #     gated by this permission system.
  piPermissionsPolicy = {
    defaultPolicy = {
      tools = "allow";
      bash = "allow";
      mcp = "allow";
      skills = "allow";
      special = "ask";
    };

    # Gate reads behind a confirmation prompt. pi-permission-system can't
    # express opencode's file-pattern denies (*.env, *.sops.yaml, *.tfvars),
    # so this is the closest substitute: every read prompts the user.
    tools = {
      read = "ask";
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
    };

    special = {
      external_directory = "ask";
    };
  };
in
{
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    {
      imports = [ inputs.pi.homeModules.default ];

      programs.pi.coding-agent = {
        enable = true;
        inherit extensions;
        skills = map (s: s.src) skills;
      };

      home.file.".pi/agent/mcp.json".text = builtins.toJSON (mkPiMcpConfig pkgs);
      home.file.".pi/agent/pi-permissions.jsonc".text = builtins.toJSON piPermissionsPolicy;
    };
}
