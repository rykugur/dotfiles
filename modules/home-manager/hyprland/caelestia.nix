# TODO: fix lock/suspend/etc shortcuts
{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.hyprland.caelestia;
in {
  imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  options.rhx.hyprland.caelestia = {
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Whether the device is a laptop or not. Controls stuff like battery, brigthness, etc being visible.";
    };

    showBluetooth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to show the bluetooth widget on the status bar.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.caelestia = {
      enable = true;

      package =
        inputs.caelestia-shell.packages.${pkgs.system}.with-cli.plugin.overrideAttrs
        (old: { buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.fftw ]; });

      settings = {
        bar = {
          status = {
            showAudio = lib.mkDefault true;
            showBattery = cfg.isLaptop;
            showBluetooth = cfg.isLaptop or cfg.showBluetooth;
          };
          workspaces = {
            activeTrail = lib.mkDefault true;
            perMonitorWorkspaces = lib.mkDefault true;
          };
        };
        general = {
          apps = { terminal = [ "ghostty --gtk-single-instance=true" ]; };
        };
        paths = { sessionGif = "undefined"; };
        services = {
          useFahrenheit = lib.mkDefault true;
          weatherLocation = lib.mkDefault "44.747998,-93.133574";
        };
      };

      cli = { enable = lib.mkDefault true; };
    };
  };
}
