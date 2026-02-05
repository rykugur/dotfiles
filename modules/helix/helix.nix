{
  inputs,
  self,
  ...
}:
{
  flake = {
    nixosModules.helix =
      { config, ... }:
      let
        username = config.meta.ryk.username;
      in
      {
        home-manager.users.${username}.imports = [ self.homeModules.helix ];
      };

    homeModules.helix =
      { pkgs, ... }:
      {
        imports = [
          self.homeModules.helix-settings
          self.homeModules.helix-languages
        ];

        programs.helix = {
          enable = true;
          package = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };

        home.file = {
          ".config/helix/snippets" = {
            source = ../../configs/snippets;
            recursive = true;
          };
        };
      };
  };
}
