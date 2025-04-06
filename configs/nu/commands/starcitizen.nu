def "starcitizen getWinePath" [] {
  nix eval nixpkgs#wineWowPackages.staging.outPath
}

def "starcitizen controllerSettings" [] {
  WINEPREFIX=$"($env.HOME)/Games/star-citizen" nix run github:fufexan/nix-gaming#wine-ge -- control
}
