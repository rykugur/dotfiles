{ self, ... }:
{
  flake.modules.homeManager.zmx =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ self.modules.homeManager.starshipFormat ];

      home.packages = [ pkgs.zmx ] ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.zsm ];

      programs.starship = lib.mkIf config.programs.starship.enable {
        prependFormat = lib.mkBefore [ "\${env_var.ZMX_SESSION}" ];
        settings.env_var.ZMX_SESSION = {
          symbol = " ";
          format = "[$symbol$env_value]($style) ";
          description = "zmx session name";
          style = "bold magenta";
        };
      };
    };
}
