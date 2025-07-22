{ pkgs, ... }: {
  default =
    pkgs.mkShell { packages = [ pkgs.just pkgs.sops pkgs.nixos-anywhere ]; };
}
