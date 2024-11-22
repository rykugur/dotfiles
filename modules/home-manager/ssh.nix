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
      defaultSopsFile = ../../hosts/${hostname}/secrets.yaml;
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      secrets.ssh_private_key = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
    };

    programs = {
      ssh = {
        enable = true;

        matchBlocks = {
          "jezrien taln tanavast taldain" = {
            identityFile = "~/.ssh/id_ed25519";
            identitiesOnly = true;
            forwardAgent = true;
            # extraOptions = {
            #   "IdentitiesOnly" = "yes";
            #   "IdentityAgent" = "~/.1password/agent.sock";
            # };
          };

          "github.com" = {
            # TODO: change to sops-nix?
            extraOptions = { "IdentityAgent" = "~/.1password/agent.sock"; };
          };
        };
      };
    };
  };
}
