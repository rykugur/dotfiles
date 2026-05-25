{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      devShells =
        lib.optionalAttrs
          (builtins.elem pkgs.stdenv.hostPlatform.system [
            "x86_64-linux"
            "aarch64-darwin"
          ])
          {
            eve-frontier =
              let
                customPkgs = import ../../pkgs { inherit pkgs; };
              in
              pkgs.mkShell {
                buildInputs = [
                  customPkgs.sui
                  pkgs.bun
                  pkgs.nodejs
                  pkgs.git-lfs
                ];

                shellHook = ''
                  echo "$(${customPkgs.sui}/bin/sui --version 2>/dev/null | head -1)"
                  if [ -f "$HOME/.sui/sui_config/client.yaml" ]; then
                    echo "network: $(${customPkgs.sui}/bin/sui client active-env 2>/dev/null || echo 'unknown')"
                  else
                    echo "network: not configured (run 'sui client' to set up)"
                  fi
                  echo ""
                  echo "  faucet:    sui client faucet"
                  echo "  localnet:  sui start --with-faucet"
                  echo "  build:     sui move build"
                  # Skip `exec nu` when invoked via direnv — nu's direnv hook
                  # would re-trigger evaluation and loop forever.
                  if [ -z "$DIRENV_DIR" ]; then
                    exec nu
                  fi
                '';
              };
          };
    };

  flake.modules.homeManager.eve-frontier =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      programs.helix = lib.mkIf config.programs.helix.enable {
        languages = {
          language-server.move-analyzer = {
            command = "${pkgs.sui}/bin/move-analyzer";
          };

          # Grammar and highlights queries come from Helix's defaults
          # (tzakian/tree-sitter-move + runtime/queries/move/highlights.scm).
          language = [
            {
              name = "move";
              scope = "source.move";
              file-types = [ "move" ];
              language-servers = [ "move-analyzer" ];
              auto-format = false;
              indent = {
                tab-width = 4;
                unit = "    ";
              };
            }
          ];
        };
      };
    };
}
