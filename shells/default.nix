{ pkgs, ... }:
let
  inherit (pkgs) lib;
  customPkgs = import ../pkgs { inherit pkgs; };
in
{
  default = pkgs.mkShell {
    packages = [
      pkgs.just
      pkgs.sops
      pkgs.nixos-anywhere
      pkgs.uv
    ];
  };

  sptarkov-server = pkgs.mkShell {
    buildInputs = with pkgs; [
      fnm
      git-lfs
    ];
    shellHook = ''
      eval "$(fnm env)"
      fnm use
      exec nu
    '';
  };

  react = pkgs.mkShell {
    buildInputs = with pkgs; [
      bun
      nodejs
    ];

    shellHook = ''
      exec nu
    '';
  };

  rust = pkgs.mkShell {
    buildInputs = with pkgs; [
      rustc
      cargo
      cargo-generate
    ];

    shellHook = ''
      exec nu
    '';
  };

}
// lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
  sui = pkgs.mkShell {
    buildInputs = [
      customPkgs.sui # also brings move-analyzer onto PATH
      pkgs.bun
      pkgs.nodejs
      pkgs.git-lfs
    ];

    shellHook = ''
      echo "sui $(${customPkgs.sui}/bin/sui --version 2>/dev/null | head -1)"
      echo "network: $(${customPkgs.sui}/bin/sui client active-env 2>/dev/null || echo 'not configured')"
      echo ""
      echo "  faucet:    sui client faucet"
      echo "  localnet:  sui start --with-faucet"
      echo "  build:     sui move build"
      exec nu
    '';
  };
}
