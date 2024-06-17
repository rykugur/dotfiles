{ config, lib, inputs, pkgs, username, ... }:
let cfg = config.modules.programs.gbarz;
in {
  options.modules.programs.gbarz.enable = lib.mkEnableOption "Enable gbar.";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      imports = [ inputs.gBar.homeManagerModules.${pkgs.system}.default ];

      programs.gBar = { enable = true; };
    };
  };
}
