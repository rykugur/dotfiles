{ self, ... }:
{
  flake.modules.homeManager.eve-online =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pyfa
        self.packages.${pkgs.stdenv.hostPlatform.system}.rift-intel-tool
      ];
    };
}
