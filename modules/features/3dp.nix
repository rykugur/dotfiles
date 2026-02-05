{ self, ... }:
{
  flake.nixosModules._3dp =
    { config, ... }:
    let
      username = config.meta.ryk.username;
    in
    {
      home-manager.users.${username} = {
        imports = [ self.homeModules._3dp ];
      };
    };

  flake.homeModules._3dp =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        qidi-slicer-bin
        freecad-wayland
      ];
    };
}
