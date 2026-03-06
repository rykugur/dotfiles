{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.ryk._1password;
in
{
  options.ryk._1password.enable = lib.mkEnableOption "Enable 1password nixOS module";

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        libsecret
      ];

      # TODO: these should be moved into their respecive modules
      etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            chrome
            vivald-bin
            # because they keep fucking changing it...
            .zen-beta-wrapped
            .zen-beta-wrapp
            .zen-beta
            zen-beta
            zen
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

    # required when 1Password -> Settings -> Security ->
    # "Unlock using system authentication service" is checked.
    services.gnome.gnome-keyring.enable = true;
  };
}
