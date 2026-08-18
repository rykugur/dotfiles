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

      home.packages = [ pkgs.zmx ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.zsm ];

      programs.starship = lib.mkIf config.programs.starship.enable {
        prependFormat = lib.mkBefore [ "\${env_var.ZMX_SESSION}" ];
        settings.env_var.ZMX_SESSION = {
          symbol = " ";
          format = "[$symbol$env_value]($style) ";
          description = "zmx session name";
          style = "bold magenta";
        };
      };

      programs.nushell = lib.mkIf config.programs.nushell.enable {
        extraConfig = ''
          source ${
            pkgs.runCommand "zmx-nushell-completions.nu" { nativeBuildInputs = [ pkgs.zmx ]; } ''
              export HOME="$TMPDIR"
              zmx completions nu > "$out"
            ''
          }
        '';
      };
    };
}
