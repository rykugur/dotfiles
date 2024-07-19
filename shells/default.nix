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

  tauri = let
    libraries = with pkgs; [
      webkitgtk
      gtk3
      cairo
      gdk-pixbuf
      glib
      dbus
      openssl_3
      librsvg
    ];
    tauriPackages = with pkgs; [
      pkg-config
      dbus
      openssl_3
      glib
      gtk3
      libsoup_3
      webkitgtk_4_1
      appimagekit
      librsvg
    ];
  in pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";

    packages = with pkgs; [ rustc yarn ] ++ tauriPackages;

    shellHook = ''
      export LD_LIBRARY_PATH=${
        pkgs.lib.makeLibraryPath libraries
      }:$LD_LIBRARY_PATH
      export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
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
