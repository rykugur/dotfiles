{ config, inputs, lib, pkgs, overlays, ... }: {
  nixpkgs.overlays = [ overlays.rust-overlay.overlays.default ];
  environment.systemPackages = [ pkgs.rust-bin.stable.latest.default ];
}
