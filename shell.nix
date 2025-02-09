let pkgs = import <nixpkgs> { };
in pkgs.mkShell { buildInputs = with pkgs; [ just sops nixos-anywhere ]; }
