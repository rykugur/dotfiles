{ pkgs }:
let
  inherit (pkgs) lib;

  servers = {
    jcodemunch = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--python"
        "3.13"
        "jcodemunch-mcp"
      ];
    };
    context-mode = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "context-mode"
      ];
      env = {
        PATH = "${pkgs.nodejs}/bin:${pkgs.coreutils}/bin:/bin:/usr/bin";
      };
    };
    mempalace = {
      command = "${pkgs.uv}/bin/uv";
      args = [
        "run"
        "--with"
        "mempalace"
        "--python"
        "3.13"
        "python"
        "-m"
        "mempalace.mcp_server"
      ];
    };
    sequential-thinking = {
      command = "${pkgs.bun}/bin/bunx";
      args = [ "@modelcontextprotocol/server-sequential-thinking" ];
    };
    context7 = {
      command = "${pkgs.bun}/bin/bunx";
      args = [ "@upstash/context7-mcp" ];
    };
  };

  pick = names: lib.getAttrs names servers;

  # Claude Code mcpConfig schema: { type = "stdio"; command; args; env?; }
  toClaudeCode =
    serverSet:
    lib.mapAttrs (
      _: s:
      {
        type = "stdio";
        inherit (s) command args;
      }
      // lib.optionalAttrs (s ? env) { inherit (s) env; }
    ) serverSet;

  # Opencode programs.opencode.settings.mcp schema:
  # { type = "local"; command = [cmd args...]; environment?; }
  toOpencode =
    serverSet:
    lib.mapAttrs (
      _: s:
      {
        type = "local";
        command = [ s.command ] ++ s.args;
      }
      // lib.optionalAttrs (s ? env) { environment = s.env; }
    ) serverSet;

  # Pi mcp.json schema is the canonical form unchanged.
  toPi = serverSet: serverSet;

  # Grok (superagent-ai/grok-cli) mcp config in ~/.grok/user-settings.json
  # under mcp.servers (array of McpServerConfig).
  # See src/utils/settings.ts in grok-cli for the type:
  # { id, label, enabled, transport: "stdio"|"http"|"sse", command?, args?, env?, url?, headers?, cwd? }
  toGrok =
    serverSet:
    lib.mapAttrsToList (
      name: s:
      {
        id = name;
        label = name;
        enabled = true;
        transport = "stdio";
        inherit (s) command args;
      }
      // lib.optionalAttrs (s ? env) { inherit (s) env; }
    ) serverSet;
in
{
  inherit
    servers
    pick
    toClaudeCode
    toOpencode
    toPi
    toGrok
    ;
}
