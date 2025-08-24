{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.hyprland.quickshell;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.caelestia-shell.packages.${pkgs.system}.default.override
      { withCli = true; }
    ];
    programs.quickshell = {
      enable = true;
      package =
        inputs.caelestia-shell.packages.${pkgs.system}.default.override {
          withCli = true;
        };
    };
  };
}
