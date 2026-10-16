{ self, ... }:
{
  flake.modules.homeManager.ai-common =
    { lib, pkgs, ... }:
    {
      imports = [ self.modules.homeManager.ai-skills ];

      home.packages = [
        pkgs.llmfit
        pkgs.rtk
        pkgs.openrig
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
