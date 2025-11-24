{ config, lib, username, ... }:
let
  cfg = config.rhx.dankMaterialShell;
  screenshotBackends = (import ../shared.nix).screenshotBackends;
in {
  options.rhx.dankMaterialShell = {
    enable =
      lib.mkEnableOption "Enable dankMaterialShell custom quickshell module.";

    screenshotBackend = lib.mkOption {
      type = lib.types.enum screenshotBackends;
      default = "none";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
