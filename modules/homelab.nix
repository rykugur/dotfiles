{ self, ... }:
{
  flake.nixosModules.homelab =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.homelab ];
    };

  flake.homeModules.homelab =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        kubectl
        kubectx # also contains kubens

        kubernetes-helm-wrapped
        helmfile-wrapped

        fluxcd
      ];

      programs.k9s = {
        enable = true;
      };

      programs.kubecolor = {
        enable = true;
      };
    };
}
