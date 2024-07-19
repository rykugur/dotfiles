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

  tauri = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";

    packages = with pkgs; [
      cairo
      glibc
      gtk3
      libsoup
      openssl
      rustc
      webkitgtk
      yarn
    ];

    shellHook = ''
      fish
      exit
    '';
  };

  nvim = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
    # packages required to build some plugins
    packages = with pkgs; [ cargo cmake gcc go nodejs luaPackages.lua ];

    shellHook = ''
      nvim
      exit
    '';
  };

  lua = pkgs.mkShell {
    packages = [
      inputs.luarocks-nix.packages.${pkgs.system}.default
      pkgs.love
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
