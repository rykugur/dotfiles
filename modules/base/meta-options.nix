{ ... }:
{
  flake.modules.nixos.meta =
    { lib, ... }:
    {
      options.ryk = {
        username = lib.mkOption {
          type = lib.types.str;
          default = "dusty";
          description = "Primary user account name";
        };
      };
    };
}
