{
  flake.nixosModules.meta =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.meta.ryk.username;
    in
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

        homePath =
          let
            basePath = if pkgs.stdenv.isDarwin then "/Users" else "/home";
          in
          lib.mkOption {
            type = lib.types.str;
            default = "${basePath}/${username}";
          };
      };
    };
}
