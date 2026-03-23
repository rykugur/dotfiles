{ inputs, ... }:
let
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
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.claude-code = inputs.nix-wrapper-modules.wrappers.claude-code.wrap {
        inherit pkgs;
        pluginDirs = mkPluginDirs pkgs;
        mcpConfig = mkClaudeCodeMcpConfig pkgs;
        settings = {
          permissions = {
            allow = [
              "Bash(helm template:*)"
              "Bash(kubectl get:*)"
              "Bash(curl:*)"
              "Bash(kubectl logs:*)"
              "Bash(gh api:*)"
              "Bash(nix search:*)"
              "WebFetch(domain:github.com)"
              "mcp__jcodemunch__index_repo"
              "mcp__context-mode__ctx_fetch_and_index"
              "mcp__context-mode__ctx_search"
            ];
          };
        };
      };
    };
}
