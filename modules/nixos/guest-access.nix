{ self, ... }:
{
  flake.modules.nixos.guest-access =
    { config, lib, username, ... }:
    {
      imports = [ self.modules.nixos.ssh-server ];

      options.ryk.guestAccess.passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Guest-local file containing a console password hash. No SOPS or private
          key provisioning is imported. When absent, new accounts stay password-locked;
          SSH public-key access and passwordless sudo still work.
          Impermanent guests must persist this file themselves.
        '';
      };

      config = {
        users.users.${username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          initialHashedPassword = if config.ryk.guestAccess.passwordFile == null then "!" else null;
          hashedPasswordFile = config.ryk.guestAccess.passwordFile;
        };
        security.sudo.wheelNeedsPassword = false;
      };
    };
}
