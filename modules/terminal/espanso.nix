{ ... }:
{
  flake.modules.homeManager.espanso =
    { config, lib, ... }:
    let
      inherit (lib) types mkOption mkIf;
    in
    {
      options.espanso = {
        snippets = mkOption {
          type = types.listOf types.attrs;
          default = [ ];
          description = "List of Espanso snippet definitions";
        };
      };

      config = mkIf config.services.espanso.enable {
        services.espanso.configs.default = {
          matches = config.espanso.snippets;
        };
      };
    };
}
