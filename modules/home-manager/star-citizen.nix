{ inputs, pkgs, ... }: {
  home.packages = [
    pkgs.aitrack

    inputs.nix-gaming.packages.${pkgs.system}.star-citizen
  ];
}
