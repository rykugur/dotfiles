{ inputs, pkgs, ... }: {

  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";

    packages = with pkgs; [ nodejs yarn ];
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
