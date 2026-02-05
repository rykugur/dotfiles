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
      nixpkgs.config = {
        permittedInsecurePackages = [
          "electron-25.9.0"
          "nexusmods-app-unfree-0.21.1"
        ];

        allowUnfree = true;
        # Workaround for https://github.com/nix-community/home-manager/issues/2942
        allowUnfreePredicate = _: true;
      };

      programs.home-manager.enable = true;
      # Nicely reload system units when changing configs
      systemd.user.startServices = "sd-switch";
    };
}
