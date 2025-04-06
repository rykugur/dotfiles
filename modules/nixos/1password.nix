{ config, lib, pkgs, username, ... }:
let cfg = config.rhx._1password;
in {
  options.rhx._1password.enable =
    lib.mkEnableOption "Enable 1password nixOS module";

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ gnome-keyring libsecret ];
      etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            chrome
            vivald-bin
            .zen-beta-wrapped
            .zen-beta-wrapp
            .zen-beta
            zen-beta
          '';
          mode = "0755";
        };
      };
    };

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${username}" ];
    };

    # can we find a better solution?
    services.gnome.gnome-keyring.enable = true;
    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart =
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };

  };
}
