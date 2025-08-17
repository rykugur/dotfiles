def "starcitizen getWinePath" [] {
  nix eval --raw $"($env.DOTFILES_DIR)#nixosConfigurations.jezrien.pkgs.wine-astral.outPath"
}

def "starcitizen controllerSettings" [] {
  WINEPREFIX=$"($env.HOME)/Games/star-citizen" nix run github:fufexan/nix-gaming#wine-ge -- control
}
