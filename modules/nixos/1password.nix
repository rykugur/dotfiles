{ ... }:
{
  flake.modules.nixos._1password =
    { username, pkgs, ... }:
    {
      environment.etc."1password/custom_allowed_browsers" = {
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

      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "${username}" ];
      };
    };
}
