{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.starcitizen;
in {
  options.rhx.starcitizen = {
    enable = lib.mkEnableOption "Enable starcitizen home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    imports = [ inputs.nix-gaming.packages.${pkgs.system}.star-citizen ];
  };
}
