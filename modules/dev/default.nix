{ lib, config, ... }: {
  imports = [ ./yaak ];

  options.ryk.dev.enable = lib.mkEnableOption "Enable dev modules";

  config = lib.mkIf config.ryk.dev.enable {
    ryk.dev = { yaak.enable = lib.mkDefault true; };
  };
}
