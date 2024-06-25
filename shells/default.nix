{ inputs, pkgs, ... }: {

  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
  };

  # react = pkgs.mkShell {
  #   NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
  #   packages = with pkgs; [
  #     nodejs
  #     prettierd
  #     yarn
  #
  #     cargo
  #     rustc
  #     rustup
  #
  #     atk
  #     gdk-pixbuf
  #     glib
  #     cairo
  #     libsoup
  #     pango
  #     pkg-config
  #     webkitgtk
  #   ];
  # };

  nvim = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
    packages = with pkgs; [ cargo cmake gcc nodejs luaPackages.lua ];

    shellHook = ''
      nvim
      exit
    '';
  };

  lua = pkgs.mkShell {
    packages = [
      inputs.luarocks-nix.packages.${pkgs.system}.default
      pkgs.lua
      pkgs.nurl
    ];

    shellHook = ''
      eval $(luarocks path --bin)
      fish
      exit
    '';
  };
}
