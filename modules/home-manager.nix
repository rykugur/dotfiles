{ inputs, self, ... }:
{
  imports = [
    inputs.home-manager.flakeModules.default
  ];

  flake.nixosModules.home-manager =
    { config, ... }:
    let
      metaCfg = config.meta.ryk;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        users.${metaCfg.username} = {
          imports = [
            self.homeModules.common
          ];

          # TODO: this probably belongs elsewhere
          # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
          home.stateVersion = "23.11";
        };
      };
    };

  flake.homeModules.common =
    { ... }:
    {
      programs.home-manager.enable = true;
      # Nicely reload system units when changing configs
      systemd.user.startServices = "sd-switch";
    };
}
