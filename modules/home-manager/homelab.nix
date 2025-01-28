{ config, lib, pkgs, ... }:
let cfg = config.rhx.homelab;
in {
  options.rhx.homelab = {
    enable = lib.mkEnableOption "Enable homelab home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kubectl
      kubectx # also contains kubens

      kubernetes-helm
      helmfile
    ];

    programs.kubecolor = { enable = true; };
  };
}
