{
  config,
  lib,
  inputs,
  username,
  ...
}: let
  cfg = config.gaming.starcitizen;
in {
  options = {
    gaming.starcitizen.enable = lib.mkEnableOption "Star Citizen";
  };

  config = lib.mkIf cfg.enable {
    programs.faceTracking.enable = true;

    boot.kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };

    home-manager.users.${username}.home.packages = [
      inputs.nix-citizen.packages.x86_64-linux.star-citizen
      inputs.nix-citizen.packages.x86_64-linux.lug-helper
    ];
  };
}
