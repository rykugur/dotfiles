{
  description = "A flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, lib, ... }:
        let
          libs = [
            pkgs.webkitgtk_4_1
            pkgs.gtk3
            pkgs.glib
            pkgs.libsoup_3
            pkgs.libayatana-appindicator
            pkgs.cairo
            pkgs.gdk-pixbuf
            pkgs.librsvg
          ];
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.bun
              pkgs.cmake
              pkgs.pkg-config
            ]
            ++ libs;

            shellHook = ''
              export LD_LIBRARY_PATH="${lib.makeLibraryPath libs}:''${LD_LIBRARY_PATH:-}"
            '';
          };
        };
    };
}
