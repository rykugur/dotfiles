{ ... }:
{
  flake.modules.homeManager.homelab =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        kubectl
        kubectx # also contains kubens

        kubernetes-helm-wrapped
        helmfile-wrapped

        fluxcd
      ];

      programs.k9s = { enable = true; };

      programs.kubecolor = { enable = true; };
    };
}
