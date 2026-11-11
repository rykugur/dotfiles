{
  config,
  lib,
  options,
  pkgs,
  ...
}:
{
  config = lib.optionalAttrs (lib.hasAttrByPath [ "ryk" "dankMaterialShell" "extraRightWidgets" ] options) {
    ryk.dankMaterialShell.extraRightWidgets = [ "logitechMouseBattery" ];

    home-manager.users.${config.ryk.username} = { config, ... }: {
      programs.dank-material-shell.plugins.logitechMouseBattery =
        lib.mkIf config.programs.dank-material-shell.enable {
          src = ./mouse-battery;
          settings.command = [
            "${pkgs.coreutils}/bin/env"
            "LC_ALL=C"
            "${lib.getExe pkgs.solaar}"
            "show"
            "G502 X PLUS"
          ];
        };
    };
  };
}
