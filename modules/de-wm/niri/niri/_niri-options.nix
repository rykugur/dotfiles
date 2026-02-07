{ lib, ... }:
{
  options.ryk.niri = {
    monitors = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Monitors to define.";
    };
  };
}
