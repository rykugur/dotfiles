{ config, lib, pkgs, ... }:
let cfg = config.ryk.homelab;
in {
  options.ryk.homelab = {
    enable = lib.mkEnableOption "Enable homelab home-manager module.";
  };

  config = lib.mkIf cfg.enable {
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
