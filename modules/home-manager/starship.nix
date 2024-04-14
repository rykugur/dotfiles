{ lib, pkgs, ... }: {
  programs.starship =
    let
      flavor = "mocha";
    in
    {
      enable = true;
      enableFishIntegration = true;
      settings = {
        palette = "catppuccin_${flavor}";
      } // builtins.fromTOML (builtins.readFile ../../configs/starship/starship-jetpack.toml)
      // builtins.fromTOML (builtins.readFile
        (pkgs.fetchFromGitHub
          {
            owner = "catppuccin";
            repo = "starship";
            rev = "5629d2356f62a9f2f8efad3ff37476c19969bd4f";
            sha256 = "sha256-nsRuxQFKbQkyEI4TXgvAjcroVdG+heKX5Pauq/4Ota0=";
          } + /palettes/${flavor}.toml));
    };

}

