{ inputs, ... }:
let
  inherit (import ./_shared.nix) allowedBashCommands;
  inherit (import ./_agents.nix) agents toOpencodeAgent;

  mkOpencodeSettings = pkgs: {
    plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
    permission = {
      "*" = "ask";
      edit = "allow";
      read = "allow";
      glob = "allow";
      grep = "allow";
      webfetch = "allow";
      websearch = "allow";
      bash = builtins.listToAttrs (
        [{ name = "*"; value = "ask"; }]
        ++ map (cmd: { name = "${cmd} *"; value = "allow"; }) allowedBashCommands
      );
    };
    mcp = {
      jcodemunch = {
        type = "local";
        command = [
          "${pkgs.uv}/bin/uvx"
          "--python"
          "3.13"
          "jcodemunch-mcp"
        ];
      };
      context-mode = {
        type = "local";
        command = [
          "${pkgs.nodejs}/bin/npx"
          "-y"
          "context-mode"
        ];
        environment = {
          PATH = "${pkgs.nodejs}/bin:${pkgs.coreutils}/bin:/bin:/usr/bin";
        };
      };
      sequential-thinking = {
        type = "local";
        command = [
          "${pkgs.bun}/bin/bunx"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };
      context7 = {
        type = "local";
        command = [
          "${pkgs.bun}/bin/bunx"
          "@upstash/context7-mcp"
        ];
      };
    };
  };
in
{
  flake.modules.homeManager.opencode =
    { pkgs, ... }:
    {
      programs.opencode = {
        enable = true;
        settings = mkOpencodeSettings pkgs;
      };

      xdg.configFile = builtins.listToAttrs (map (agent: {
        name = "opencode/agents/${agent.name}.md";
        value.text = toOpencodeAgent agent;
      }) agents);
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.opencode = inputs.nix-wrapper-modules.wrappers.opencode.wrap {
        inherit pkgs;
        settings = mkOpencodeSettings pkgs;
      };
    };
}
