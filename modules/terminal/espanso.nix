{ lib, config, ... }:

let
  inherit (lib) types mkEnableOption mkOption mkIf;
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
}
