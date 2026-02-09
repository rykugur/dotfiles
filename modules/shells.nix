{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.sops
            pkgs.nixos-anywhere
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
      };
    };
}
