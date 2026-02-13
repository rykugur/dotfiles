{ inputs, self, ... }:
{
  flake.homeModules.sops =
    { config, osConfig, ... }:
    let
      metaCfg = osConfig.meta.ryk;
    in
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        defaultSopsFile = self + "/modules/hosts/${metaCfg.hostname}/secrets.yaml";
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

        secrets = {
          homelab_ssh_private_key = { };
        };
      };
    };
}
