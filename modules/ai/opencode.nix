{ inputs, ... }:
let
  inherit (import ./_shared.nix) allowedBashCommands;
  inherit (import ./_agents.nix) resolveAgents toOpencodeAgent;

  opencodeModelMap = {
    # OpenCode Zen
    sonnet = "opencode/claude-sonnet-4-6";
    opus = "opencode/claude-opus-4-6";
    haiku = "opencode/claude-haiku-4-5";
    big-pickle = "opencode/big-pickle";
    minimax-m25-free = "opencode/minimax-m2.5-free";
    mimo-v2-pro-free = "opencode/mimo-v2-pro-free";
    # OpenCode Go
    glm-5 = "opencode-go/glm-5";
    kimi-k25 = "opencode-go/kimi-k2.5";
    minimax25 = "opencode-go/minimax-m2.5";
    minimax27 = "opencode-go/minimax-m2.7";
  };

  tierModels = {
    reference = opencodeModelMap.mimo-v2-pro-free;
    technical = opencodeModelMap.kimi-k25;
  };

  agentOverrides = { };

  agents = resolveAgents { inherit tierModels agentOverrides; };

  mkOpencodeSettings = pkgs: {
    plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
    permission = {
      "*" = "ask";
      edit = "ask";
      read = "allow";
      glob = "allow";
      grep = "allow";
      webfetch = "allow";
      websearch = "allow";
      "jcodemunch_*" = "allow";
      "context7_*" = "allow";
      "context-mode_ctx_*" = "allow";
      # for superpowers
      "brainstorming" = "allow";
      "todowrite" = "allow";
      "requesting-code-review" = "allow";
      "test-driven-development" = "allow";
      "executing-plans" = "allow";
      bash = builtins.listToAttrs (
        [
          {
            name = "*";
            value = "ask";
          }
        ]
        ++ map (cmd: {
          name = "${cmd} *";
          value = "allow";
        }) allowedBashCommands
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

      xdg.configFile = {
        "opencode/tui.json".text = builtins.toJSON {
          "$schema" = "https://opencode.ai/tui.json";
          scroll_acceleration = true;
        };
        "opencode/opencode-yolo.json".text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          permission = {
            "*" = {
              "*" = "allow";
            };
          };
        };
      }
      // builtins.listToAttrs (
        map (agent: {
          name = "opencode/agents/${agent.name}.md";
          value.text = toOpencodeAgent agent;
        }) agents
      );

      home.packages = [
        (pkgs.writeShellScriptBin "opencode-yolo" ''
          export OPENCODE_CONFIG="$HOME/.config/opencode/opencode-yolo.json"
          exec ${pkgs.opencode}/bin/opencode "$@"
        '')
      ];
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
