{ config, inputs, lib, pkgs, hostname, ... }:
let cfg = config.rhx.ssh;
in {
  options.rhx.ssh = {
    enable = lib.mkEnableOption "Enable ssh home-manager module.";
  };

  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [ age sops ];

    sops = {
      secrets.ssh_private_key = {
        sopsFile = ../../hosts/${hostname}/secrets.yaml;
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
        mode = "0400";
      };
    };

    programs = {
      ssh = {
        enable = true;

        extraConfig = ''
          AddKeysToAgent yes
        '';

        matchBlocks = {
          "jezrien taln tanavast taldain homelab*" = {
            identityFile = "~/.ssh/id_ed25519";
            identitiesOnly = true;
            forwardAgent = true;
          };

          "github.com" = {
            identityFile = "~/.ssh/id_ed25519";
            identitiesOnly = true;
            forwardAgent = false;
          };
        };
      };
    };
  };
}
