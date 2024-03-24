# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs ? import <nixpkgs> { }, ... }: {
  fetch7zip = pkgs.callPackage ./fetch7zip.nix { };
  lampray = pkgs.callPackage ./lampray { };
  n0la_rcon = pkgs.callPackage ./n0la_rcon.nix { };
  starsectorMods = pkgs.callPackage ./starsector { };
}
