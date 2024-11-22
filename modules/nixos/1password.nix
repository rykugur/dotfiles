{ config, lib, username, ... }:
let cfg = config.rhx._1password;
in {
  options.rhx._1password.enable =
    lib.mkEnableOption "Enable 1password nixOS module";

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          vivald-bin
          .zen-wrapped
        '';
        mode = "0755";
      };
    };

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${username}" ];
    };
  };
}
