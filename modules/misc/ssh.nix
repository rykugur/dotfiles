{ self, ... }:
{
  flake.modules.nixos.ssh =
    { username, ... }:
    {
      imports = [ self.modules.nixos.ssh-server ];

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
