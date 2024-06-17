{ config, lib, inputs, username, ... }:
let cfg = config.modules.gaming.starcitizen;
in {
  options.modules.gaming.starcitizen.enable = lib.mkEnableOption "Star Citizen";

  config = lib.mkIf cfg.enable {
    modules.programs.faceTracking.enable = true;

    boot.kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };

    networking.extraHosts = ''
      127.0.0.1 modules-cdn.eac-prod.on.epicgames.com
    '';

    # home-manager.users.${username}.home.packages = [
    # ];
  };
}
