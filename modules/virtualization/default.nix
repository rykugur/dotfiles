{
  config,
  lib,
  ...
}:
let
  cfg = config.ryk.virtualization;
in
{
  options.ryk.virtualization = {
    enable = lib.mkEnableOption "Enable virtualization module.";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd.enable = true;
      virtiofsd.enable = true;
    };

    # home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
