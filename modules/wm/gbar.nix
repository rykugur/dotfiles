{
  config,
  lib,
  inputs,
  username,
  ...
}: let
  cfg = config.programs.gbarz;
  system = config.system.build.system;
in {
  options.programs.gbarz.enable = lib.mkEnableOption "Enable gbar.";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      imports = [
        inputs.gBar.homeManagerModules.${system}.default
      ];

      programs.gBar = {
        enable = true;
      };
    };
  };
}
