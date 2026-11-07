# `nix-defaults` used to set these two lines, which is why consumers outside
# this repo had to splice `inputs.self = dotfiles` into their specialArgs just
# to evaluate it. The shared module no longer does; hosts in this flake that
# want the custom package set import this instead.
#
# Taln sets `nixpkgs.overlays` itself in its own `_configuration.nix` and must
# not import this as well.
{ inputs, ... }:
{
  flake.modules.nixos.dotfiles-overlays = {
    nixpkgs.overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
    ];
  };
}
