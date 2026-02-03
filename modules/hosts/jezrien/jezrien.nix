{
  inputs,
  self,
  ...
}:
{
  flake = {
    nixosConfigurations.jezrien = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.jezrien-config
      ];
    };

    nixosModules.jezrien-config = {
      imports = [
        ./_hardware-configuration.nix
        ./_configuration.nix

        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
      ]
      ++ (with inputs.nixos-hardware.nixosModules; [
        common-pc
        common-pc-ssd
        common-cpu-amd
        common-gpu-amd
      ]);

      ### custom module stuff

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        # extraSpecialArgs = { inherit inputs self; };
        users.dusty = {
          imports = [ self.homeModules.dusty ];

          # TODO: rest of jezrien/home.nix config

          programs.home-manager.enable = true;
          # Nicely reload system units when changing configs
          systemd.user.startServices = "sd-switch";
          # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
          home.stateVersion = "23.11";
        };
      };
    };
  };
}
