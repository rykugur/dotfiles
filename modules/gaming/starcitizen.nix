{ config, inputs, lib, pkgs, username, ... }:
let cfg = config.modules.gaming.starcitizen;
in {
  options.modules.gaming.starcitizen.enable = lib.mkEnableOption "Star Citizen";

  config = lib.mkIf cfg.enable {
    modules.programs.faceTracking.enable = true;

    boot.kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };

    home-manager.users.${username} = {
      home.packages =
        [ inputs.nix-gaming.packages.${pkgs.system}.star-citizen ];
    };
  };
}
