# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs ? import <nixpkgs> { }, ... }: {
  opentrack = pkgs.callPackage ./opentrack { };
  starsectorMods = pkgs.callPackage ./starsector { };
  tpm = pkgs.callPackage ./tpm.nix { };
}
