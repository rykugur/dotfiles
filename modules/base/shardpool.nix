# These modules now live in github:rykugur/shardpool. They are re-exported
# here under the names they had before the move, so every host in this flake
# keeps working unchanged and there is exactly one definition of each.
#
# `flake.lib.dustySshKeys` is re-exported too: demiurge imports the SSH key
# list through its existing dotfiles input, and should not need a second flake
# input just to read three public keys.
{ inputs, ... }:
{
  flake.modules.nixos = {
    inherit (inputs.shardpool.modules.nixos)
      btrfs-rollback
      comin
      guest-access
      helix-guest
      helix-root
      impermanence
      meta
      nix-defaults
      ssh-server
      ;
  };

  flake.modules.homeManager = {
    inherit (inputs.shardpool.modules.homeManager)
      helix
      helix-lxc
      starshipFormat
      television
      yazi
      zmx
      ;
  };

  flake.lib.dustySshKeys = inputs.shardpool.lib.dustySshKeys;
}
