{ self, ... }:
{
  flake.modules.nixos.eve-online =
    { config, ... }:
    let
      username = config.ryk.username;
    in
    {
      home-manager.users.${username}.imports = [ self.modules.homeManager.eve-online ];
    };

  flake.modules.homeManager.eve-online =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pyfa
        self.packages.${pkgs.stdenv.hostPlatform.system}.rift-intel-tool
      ];
    };
}
