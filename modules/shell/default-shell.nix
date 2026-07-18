{ self, ... }:
{
  flake.modules.homeManager.shell =
    { config, lib, osConfig, ... }:
    {
      imports = with self.modules.homeManager; [
        fish
        nushell
      ];

      options.ryk.defaultShell = lib.mkOption {
        type = lib.types.enum [ "fish" "nushell" "bash" ];
        # Mirror the system choice; fall back for non-NixOS (darwin) eval.
        default = osConfig.ryk.defaultShell or "nushell";
        description = "Which shell's home-manager config is active.";
      };

    };
}
