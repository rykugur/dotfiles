{ pkgs, ... }:
{
  default = pkgs.mkShell {
    packages = [
      pkgs.just
      pkgs.sops
      pkgs.age
      pkgs.nixos-anywhere
      # infra/proxmox: VM lifecycle on roshar
      pkgs.opentofu
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

  ### variants for nix-direnv

  react-env = pkgs.mkShell {
    buildInputs = with pkgs; [
      bun
      nodejs
    ];
  };

  rust-env = pkgs.mkShell {
    buildInputs = with pkgs; [
      rustc
      cargo
      cargo-generate
    ];
  };
}
