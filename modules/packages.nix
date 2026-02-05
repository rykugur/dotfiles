{ ... }:
{
  perSystem =
    { inputs', ... }:
    {
      packages = {
        audiorelay = inputs'.ryze312-stackpkgs.packages.audiorelay;
      };
    };
}
