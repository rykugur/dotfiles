{ inputs, ... }:
let
  inherit (import ./_agents.nix) resolveAgents toClaudeCodeAgent;

  allowedBashCommands = [
    "curl"
    "gh api"
    "helm template"
    "kubectl get"
    "kubectl logs"
    "nix search"
    "git"
    "ls"
    "find"
  ];

  skills = [
    { name = "frontend-design"; src = "${inputs.skills-anthropic}/skills/frontend-design"; }
    { name = "web-design-guidelines"; src = "${inputs.skills-vercel}/skills/web-design-guidelines"; }
  ];

  tierModels = {
    reference = "claude-haiku-4-5";
    technical = "claude-sonnet-4-6";
  };

  agentOverrides = { };

  agents = resolveAgents { inherit tierModels agentOverrides; };

  mkClaudeCodeMcpConfig = pkgs: {
    jcodemunch = {
      type = "stdio";
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--python"
        "3.13"
        "jcodemunch-mcp"
      ];
    };
    context-mode = {
      type = "stdio";
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "context-mode"
      ];
      env = {
        PATH = "${pkgs.nodejs}/bin:${pkgs.coreutils}/bin:/bin:/usr/bin";
      };
    };
    sequential-thinking = {
      type = "stdio";
      command = "${pkgs.bun}/bin/bunx";
      args = [ "@modelcontextprotocol/server-sequential-thinking" ];
    };
  };

  mkPluginDirs = pkgs: [
    "${inputs.superpowers}"
    "${inputs.claude-plugins-official}/plugins/code-simplifier"
    # context7 plugin with .mcp.json patched to use bunx instead of failing HTTP endpoint
    "${pkgs.runCommand "context7-plugin" { } ''
      cp -r ${inputs.context7}/plugins/claude/context7 $out
      chmod -R u+w $out
      cat > $out/.mcp.json << 'EOF'
      {
        "context7": {
          "type": "stdio",
          "command": "${pkgs.bun}/bin/bunx",
          "args": ["@upstash/context7-mcp"]
        }
      }
      EOF
    ''}"
  ];

  claudeCodeSettings = {
    permissions = {
      allow =
        map (cmd: "Bash(${cmd}:*)") allowedBashCommands
        ++ [
          "mcp__jcodemunch__*"
          "mcp__context-mode__*"
          "mcp__plugin_context7-plugin_context7__*"
          "WebFetch(domain:github.com)"
        ];
    };
  };

  mkWrappedClaudeCode =
    pkgs:
    inputs.nix-wrapper-modules.wrappers.claude-code.wrap {
      inherit pkgs;
      pluginDirs = mkPluginDirs pkgs;
      mcpConfig = mkClaudeCodeMcpConfig pkgs;
      settings = claudeCodeSettings;
    };
in
{
  flake.modules.homeManager.claude-code =
    { pkgs, ... }:
    {
      home.packages = [ (mkWrappedClaudeCode pkgs) ];
      home.file = builtins.listToAttrs (
        map (agent: {
          name = ".claude/agents/${agent.name}.md";
          value.text = toClaudeCodeAgent agent;
        }) agents
        ++ map (skill: {
          name = ".claude/skills/${skill.name}/SKILL.md";
          value.source = "${skill.src}/SKILL.md";
        }) skills
      );
    };

  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.claude-code = mkWrappedClaudeCode pkgs;
    };
}
