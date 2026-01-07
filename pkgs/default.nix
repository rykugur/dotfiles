# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs ? import <nixpkgs> { }, ... }: {
  opentrack = pkgs.callPackage ./opentrack.nix { };
  opentrack-StarCitizen = pkgs.callPackage ./opentrack-StarCitizen.nix { };

  starsectorMods = pkgs.callPackage ./starsector { };

  tpm = pkgs.callPackage ./tpm.nix { };

  rift-intel-tool = pkgs.callPackage ./rift-intel-tool.nix { };
}
