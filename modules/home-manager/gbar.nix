{
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.gbar;
  system = "x86_64-linux";
in {
  options = {
    gbar.enable = lib.mkEnableOption "enable gbar home-manager module";
  };

  imports = [
    inputs.gBar.homeManagerModules.${system}.default
  ];

  config = lib.mkIf cfg.enable {
    programs.gBar = {
      enable = true;
    };
  };

  #
  # programs.gBar = {
  #   enable = true;
  # };
}
