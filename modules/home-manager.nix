{ inputs, ... }:
{
  imports = [
    inputs.home-manager.flakeModules.default
  ];
}
