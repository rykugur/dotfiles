{ config, lib, username, ... }:
let cfg = config.rhx.dankMaterialShell;
in {
  options.rhx.dankMaterialShell = {
    enable =
      lib.mkEnableOption "Enable dankMaterialShell custom quickshell module.";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
