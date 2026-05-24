# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  suiVersion = "1.72.2";
in
{
  ### gaming
  # star citizen
  opentrack = pkgs.callPackage ./opentrack.nix { };
  opentrack-StarCitizen = pkgs.callPackage ./opentrack-StarCitizen.nix { };
  # misc
  jackify = pkgs.callPackage ./jackify.nix { };
  eve-wrench = pkgs.callPackage ./eve-wrench.nix { };
  rift-intel-tool = pkgs.callPackage ./rift-intel-tool.nix { };

  ### misc
  rackpeek = pkgs.callPackage ./rackpeek.nix { };
  tpm = pkgs.callPackage ./tpm.nix { };

  ### sui/move (eve frontier)
  sui = pkgs.callPackage ./sui.nix { version = suiVersion; };
}
