{
  config,
  inputs,
  lib,
  pkgs,
  overlays,
  ...
}: {
  # TODO: can this be moved to a develop shell?
  nixpkgs.overlays = [overlays.rust-overlay.overlays.default];
  environment.systemPackages = with pkgs; [
    rust-bin.stable.latest.default
    rustup
  ];
}
