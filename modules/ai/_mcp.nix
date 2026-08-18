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
    context7 = {
      command = "${pkgs.bun}/bin/bunx";
      args = [ "@upstash/context7-mcp" ];
    };

    # N95 iGPU reranker still takes 30-90s even Vulkan-accelerated
    # (see homelab wiki [[arcanum-mcp]]); default 30s client timeout
    # is too tight.
    arcanum = {
      type = "http";
      url = "https://arcanum.k8s.local.ryk.sh/mcp";
      timeout = 90000;
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

  # OMP (oh-my-pi) mcp.json schema is the canonical form unchanged, same
  # shape as Pi's but named distinctly: modules/ai/pi.nix targets the
  # unrelated lukasl-dev/pi.nix tool, not OMP.
  toOhMyPi = serverSet: serverSet;

  # Hermes Agent config.yaml `mcp_servers` schema:
  # stdio: { command; args; env?; }; HTTP: { url; headers?; timeout?; ... }.
  # See https://hermes-agent.nousresearch.com/docs/reference/mcp-config-reference
  toHermes =
    serverSet:
    lib.mapAttrs (
      _: s:
      if s ? command then
        { inherit (s) command args; } // lib.optionalAttrs (s ? env) { inherit (s) env; }
      else
        { inherit (s) url; } // lib.optionalAttrs (s ? timeout) { inherit (s) timeout; }
    ) serverSet;

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
    toOhMyPi
    toGrok
    toHermes
    ;
}
