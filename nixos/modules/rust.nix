{ config, inputs, lib, pkgs, overlays, ... }: {
  nixpkgs.overlays = [ overlays.rust-overlay.overlays.default ];
  environment.systemPackages = with pkgs; [
    rust-bin.stable.latest.default
    rustup
  ];
}
