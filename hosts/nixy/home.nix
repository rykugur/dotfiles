{ pkgs, ... }: {
  imports = [ ../../modules/home-manager/helix.nix ];

  rhx.helix.enable = true;
}
