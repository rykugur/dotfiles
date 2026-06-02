{ ... }:
{
  flake.modules.homeManager.devenv =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      devenvNushellTemplate = pkgs.writeText "devenv-nushell.nix" ''
        { pkgs, ... }:
        {
          packages = [
            pkgs.nushell
          ];

          enterShell = '''
            exec nu
          ''';
        }
      '';
    in
    {
      home.packages = [ pkgs.devenv ];

      programs.nushell.extraConfig = lib.mkIf config.programs.nushell.enable ''
        def devenv-init [] {
          ^devenv init
          cp ${devenvNushellTemplate} devenv.nix
          chmod u+w devenv.nix
        }
      '';
    };
}
