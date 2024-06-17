# mechanical keyboards
{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.keebs;
in {
  options.modules.programs.keebs.enable =
    lib.mkEnableOption "Enable keebs (mechanical keyboards) module.";

  config = lib.mkIf cfg.enable {
    hardware.keyboard.qmk.enable = true;

    environment.systemPackages = [ pkgs.via pkgs.vial ];

    services.udev.packages = [ pkgs.via pkgs.vial ];

    home-manager.users.${username} = {
      home = {
        packages = [ pkgs.keebs-via.madnoodle-micro-pad ];

        file = {
          ".via-config-files/noodlepad-micro" = {
            source = pkgs.keebs-via.madnoodle-micro-pad;
          };
        };
      };
    };
  };
}
