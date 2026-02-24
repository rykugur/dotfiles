# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  ### gaming
  # star citizen
  opentrack = pkgs.callPackage ./opentrack.nix { };
  opentrack-StarCitizen = pkgs.callPackage ./opentrack-StarCitizen.nix { };
  # misc
  jackify = pkgs.callPackage ./jackify.nix { };
  rift-intel-tool = pkgs.callPackage ./rift-intel-tool.nix { };
  starsectorMods = pkgs.callPackage ./starsector { };

  ### misc
  rackpeek = pkgs.callPackage ./rackpeek.nix { };
  tpm = pkgs.callPackage ./tpm.nix { };
}
