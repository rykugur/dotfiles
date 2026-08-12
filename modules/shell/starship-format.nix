{ ... }:
{
  flake.modules.homeManager.starshipFormat =
    { lib, ... }:
    {
      key = "starship-format";

      options.programs.starship.prependFormat = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Format fragments rendered before Starship's base prompt format.";
      };
    };
}
