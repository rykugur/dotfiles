{ inputs, ... }:
{
  flake.modules.homeManager.amethyst =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.amethyst.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
