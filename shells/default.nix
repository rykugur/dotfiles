{ pkgs, ... }: {
  default =
    pkgs.mkShell { packages = [ pkgs.just pkgs.sops pkgs.nixos-anywhere ]; };

  sptarkov-server = pkgs.mkShell {
    buildInputs = with pkgs; [ fnm git-lfs ];
    shellHook = ''
      export WINEPREFIX=/home/dusty/tmp/eft-spt
      eval "$(fnm env)"
      fnm use
    '';
  };
}
