{ ... }:
{
  flake.modules.homeManager.carapace =
    { config, ... }:
    {
      programs.carapace = {
        enable = true;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;
      };

      # Bridge kubecolor completions to kubectl so `alias kubectl = kubecolor` gets completions
      xdg.configFile."carapace/specs/kubecolor.yaml".text = builtins.toJSON {
        name = "kubecolor";
        description = "colorized kubectl";
        parsing = "disabled";
        completion = {
          positionalany = [ "$carapace.bridge.CarapaceBin([kubectl])" ];
        };
      };
    };
}
