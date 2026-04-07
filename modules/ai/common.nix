{ ... }:
{
  flake.modules.homeManager.ai-common =
    { lib, pkgs, ... }:
    let
      mempalace = pkgs.writeShellScriptBin "mempalace" ''
        exec ${pkgs.uv}/bin/uvx --python 3.13 mempalace "$@"
      '';
    in
    {
      home.packages = [
        pkgs.rtk
        mempalace
      ];

      home.activation.rtkInitClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --auto-patch
      '';

      home.activation.rtkInitOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --opencode --auto-patch
      '';

      home.activation.rtkInitCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --codex
      '';
    };
}
