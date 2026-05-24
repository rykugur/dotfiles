{ pkgs, ... }:
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

  react-env = pkgs.mkShell {
    buildInputs = with pkgs; [
      bun
      nodejs
    ];
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

  rust-env = pkgs.mkShell {
    buildInputs = with pkgs; [
      rustc
      cargo
      cargo-generate
    ];
  };
}
