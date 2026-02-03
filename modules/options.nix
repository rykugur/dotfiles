{ lib, ... }:
{
  options.ryk = {
    features = lib.mkOption {
      type = lib.types.submodule {
        options = {
          helix = lib.mkEnableOption "Enable helix editor feature";
        };
      };
      default = { };
      description = "Feature toggles";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "dusty";
    };
  };
}
