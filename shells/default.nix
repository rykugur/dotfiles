{ pkgs, ... }: {
  default =
    pkgs.mkShell { packages = [ pkgs.just pkgs.sops pkgs.nixos-anywhere ]; };

  sptarkov-server = pkgs.mkShell {
    buildInputs = with pkgs; [ fnm git-lfs ];
    shellHook = ''
      eval "$(fnm env)"
      fnm use
    '';
  };

  react = pkgs.mkShell { buildInputs = with pkgs; [ bun nodejs ]; };
}
