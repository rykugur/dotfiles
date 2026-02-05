{ inputs, self, ... }:
{
  flake.nixosModules.ssh =
    { config, ... }:
    let
      metaCfg = config.meta.ryk;
      username = metaCfg.username;
    in
    {

      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      users.users.${username}.openssh.authorizedKeys.keys = [
        # "personal"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
        # jezrien
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+urk8awyDQhOmONXIsAcHzaIlvHSiTD4rL/5GAHo6D"
        # taln
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKORtO51gYjGRuP3pP/paOe8NcBfQvrcZLSSwc4bqpT"
      ];

      home-manager.users.${username}.imports = [ self.homeModules.ssh ];
    };

  flake.homeModules.ssh =
    {
      config,
      osConfig,
      pkgs,
      ...
    }:
    let
      metaCfg = osConfig.meta.ryk;
      hostname = metaCfg.hostname;
    in
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      home.packages = with pkgs; [
        age
        sops
      ];

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
          enableDefaultConfig = false;

          matchBlocks = {
            "*" = {
              forwardAgent = false;
              addKeysToAgent = "no";
              compression = false;
              serverAliveInterval = 0;
              serverAliveCountMax = 3;
              hashKnownHosts = false;
              userKnownHostsFile = "~/.ssh/known_hosts";
              controlMaster = "no";
              controlPath = "~/.ssh/master-%r@%n:%p";
              controlPersist = "no";
            };

            "*.local.ryk.sh" = {
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
