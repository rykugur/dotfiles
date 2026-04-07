{ ... }:
{
  flake.modules.homeManager.ai-common =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.rtk ];

      home.activation.rtkInitClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --auto-patch
      '';

      home.activation.rtkInitOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --opencode --auto-patch
      '';

      home.activation.rtkInitCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.rtk}/bin/rtk init -g --codex --auto-patch
      '';
    };
}
