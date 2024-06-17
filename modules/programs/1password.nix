{ config, lib, username, ... }:
let cfg = config.modules.programs._1password;
in {
  options.modules.programs._1password.enable =
    lib.mkEnableOption "Enable 1password";

  config = lib.mkIf cfg.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${username}" ];
    };
  };
}
