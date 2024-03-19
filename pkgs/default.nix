# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs, ... }: {
  fetch7zip = pkgs.callPackage ./fetch7zip.nix { };
  lampray = pkgs.callPackage ./lampray { };
  starsectorMods = pkgs.callPackage ./starsector/mods.nix { };
}
