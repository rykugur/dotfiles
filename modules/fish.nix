{ self, ... }:
{
  flake.nixosModules.fish =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.fish ];
    };

  flake.homeModules.fish =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        babelfish

        grc

        fishPlugins.autopair
        fishPlugins.grc
        fishPlugins.fzf-fish
        fishPlugins.z
      ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          source ~/.dotfiles/configs/fish/config.fish
        '';
      };

      programs.fzf.enable = true;

      # programs.zoxide = {
      #   enable = true;
      #   enableFishIntegration = true;
      # };
    };
}
