def "starcitizen getWinePath" [] {
  nix eval nixpkgs#wineWowPackages.staging.outPath
}
