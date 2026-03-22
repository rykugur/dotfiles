{ ... }:
{
  flake.modules.homeManager.opencode =
    { pkgs, ... }:
    {
      programs.opencode = {
        enable = true;

        settings = {
          permission = {
            "*" = "ask";
            edit = "allow";
            read = "allow";
            glob = "allow";
            grep = "allow";
            bash = {
              "*" = "ask";
              "git *" = "allow";
              "ls *" = "allow";
              "find *" = "allow";
            };
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
          };
          plugin = [
            "opencode-superpowers"
            "opencode-code-simplifier"
            "opencode-context7"
          ];
        };
      };
    };
}
