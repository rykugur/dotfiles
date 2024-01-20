{ inputs, pkgs, ... }: {
  home.packages = [
    inputs.nix-gaming.packages.${pkgs.system}.star-citizen
  ];
}
