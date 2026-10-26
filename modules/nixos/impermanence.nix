{ inputs, ... }:
{
  flake.modules.nixos.impermanence = inputs.impermanence.nixosModules.impermanence;
}
