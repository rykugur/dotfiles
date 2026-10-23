{ self, ... }:
{
  flake.modules.nixos.ssh =
    { username, ... }:
    {
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      users.users.${username}.openssh.authorizedKeys.keys = import ./_dusty-ssh-keys.nix;

      home-manager.users.${username}.imports = [ self.modules.homeManager.ssh ];
    };

  flake.modules.homeManager.ssh =
    { config, hostname, ... }:
    {
      sops = {
        secrets.ssh_private_key = {
          sopsFile = ../hosts/${hostname}/secrets.yaml;
          path = "${config.home.homeDirectory}/.ssh/id_ed25519";
          mode = "0400";
        };
      };

      programs = {
        ssh = {
          enable = true;
          enableDefaultConfig = false;

          settings = {
            "*" = {
              ForwardAgent = false;
              AddKeysToAgent = "no";
              Compression = false;
              ServerAliveInterval = 0;
              ServerAliveCountMax = 3;
              HashKnownHosts = false;
              UserKnownHostsFile = "~/.ssh/known_hosts";
              ControlMaster = "no";
              ControlPath = "~/.ssh/master-%r@%n:%p";
              ControlPersist = "no";
            };

            "*.local.ryk.sh" = {
              IdentityFile = "~/.ssh/id_ed25519";
              IdentitiesOnly = true;
              ForwardAgent = true;
            };

            "github.com" = {
              IdentityFile = "~/.ssh/id_ed25519";
              IdentitiesOnly = true;
              ForwardAgent = false;
            };
          };
        };
      };
    };
}
