def "starcitizen getWinePath" [] {
  # nix eval --raw $"($env.DOTFILES_DIR)#nixosConfigurations.(hostname).pkgs.wine-astral.outPath"
  print $"Replaced with symlink - see ($env.HOME)/.wine-astral"
}

def "starcitizen controllerSettings" [] {
  # WINEPREFIX=$"($env.HOME)/Games/star-citizen" nix run github:fufexan/nix-gaming#wine-ge -- control
  print "Old command stopped working; run `rsi-launcher --shell`"
  print " "
  print "and then run `wine control joy.cpl` for now."
}
