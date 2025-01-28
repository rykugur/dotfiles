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

    sops = {
      secrets.config_yaml = { sopsFile = ../../hosts/homelab/secrets.yaml; };
    };

    programs.kubecolor = { enable = true; };

    programs.nushell = lib.mkIf config.rhx.nushell.enable {
      extraEnv = ''
        $env.KUBECONFIG = "${config.sops.secrets.config_yaml.path}"
      '';
      extraConfig = ''
        alias k = kubecolor
      '';
    };
  };
}
