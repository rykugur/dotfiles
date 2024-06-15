{ pkgs, ... }: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
    nativeBuildInputs = with pkgs; [ ];
  };

  react = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
    nativeBuildInputs = with pkgs; [
      nodejs_22
      prettierd
      yarn

      cargo
      rustc
      rustup

      atk
      gdk-pixbuf
      glib
      cairo
      libsoup
      pango
      pkg-config
      webkitgtk
    ];
  };
}
