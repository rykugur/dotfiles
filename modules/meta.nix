{
  flake.nixosModules.meta =
    {
      lib,
      ...
    }:
    {
      options.meta.ryk = {
        username = lib.mkOption {
          type = lib.types.str;
          default = "dusty";
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          default = "undefined";
        };
      };
    };
}
