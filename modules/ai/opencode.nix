{ inputs, ... }:
let
  mkOpencodeSettings = pkgs: {
    plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
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
