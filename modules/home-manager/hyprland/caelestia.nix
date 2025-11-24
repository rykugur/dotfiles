# TODO: fix lock/suspend/etc shortcuts
# TODO: move this to desktop module
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
      systemd.enable = false;

      package =
        inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli.override {
          libcava = pkgs.libcava.overrideAttrs
            (prev: final: { propagatedBuildInputs = prev.buildInputs; });
        };

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
          apps = {
            explorer = [ "nautilus" ];
            terminal = [ "ghostty --gtk-single-instance=true" ];
          };
          idle = {
            timeouts = [
              {
                timeout = 600;
                idleAction = "lock";
              }
              {
                timeout = 900;
                idleAction = "dpms off";
                returnAction = "dpms on";
              }
            ];
          };
        };
        paths = { sessionGif = "undefined"; };
        services = {
          useFahrenheit = lib.mkDefault true;
          weatherLocation = lib.mkDefault "44.747998,-93.133574";
        };
        session = { commands = { hibernate = [ "systemctl" "suspend" ]; }; };
      };

      cli = { enable = lib.mkDefault true; };
    };
  };
}
