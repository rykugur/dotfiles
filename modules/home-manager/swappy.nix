{
  config,
  lib,
  ...
}: let
  cfg = config.swappy;
in {
  options = {
    swappy.enable = lib.mkEnableOption "Enable swappy";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".config/swappy" = {
        source = ../../configs/swappy;
        recursive = true;
      };
    };
  };
}
