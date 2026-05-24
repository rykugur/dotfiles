{ ... }:
{
  flake.modules.homeManager.sui =
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

          grammar = [
            {
              name = "move";
              source = {
                git = "https://github.com/MystenLabs/sui.git";
                rev = "testnet-v${pkgs.sui.version}";
                subpath = "external-crates/move/tooling/tree-sitter";
              };
            }
          ];

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

      home.file.".config/helix/runtime/queries/move" = lib.mkIf config.programs.helix.enable {
        source = ../../configs/helix-move/queries;
        recursive = true;
      };
    };
}
