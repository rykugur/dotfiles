{
  config,
  lib,
  username,
  ...
}: let
  cfg = config.programs._1passwordz;
in {
  options.programs._1passwordz.enable = lib.mkEnableOption "Enable 1password";

  config = lib.mkIf cfg.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = ["${username}"];
    };
  };
}
