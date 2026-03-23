{ ... }:
{
  flake.modules.homeManager.television =
    { config, lib, pkgs, ... }:
    {
      programs.television = {
        enable = true;

        enableBashIntegration = config.programs.bash.enable;
        enableFishIntegration = config.programs.fish.enable;
        enableZshIntegration = config.programs.zsh.enable;

        settings = {
          ui = {
            theme = "catppuccin";
          };
        };
      };

      # no programs.television.enableNushellIntegration option :(
      programs.nushell = lib.mkIf (config.programs.nushell.enable) {
        extraConfig = ''
          mkdir ($nu.data-dir | path join "vendor/autoload")
          ${lib.getExe pkgs.television} init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")
        '';
      };
    };
}
