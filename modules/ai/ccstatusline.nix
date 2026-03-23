{ ... }:
{
  flake.modules.homeManager.ccstatusline =
    { config, pkgs, ... }:
    let
      configFile = "${config.home.homeDirectory}/.dotfiles/configs/ccstatusline/settings.json";
      ccstatusline = pkgs.writeShellScriptBin "ccstatusline" ''
        exec ${pkgs.bun}/bin/bun x -y ccstatusline@latest --config "${configFile}" "$@"
      '';
    in
    {
      home.packages = [ ccstatusline ];
    };
}
