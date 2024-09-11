{ config, lib, username, ... }:
let cfg = config.modules.services.ssh;
in {
  options.modules.services.ssh.enable = lib.mkEnableOption "Enable SSH.";

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    users.users.${username}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
    ];

    home-manager.users.${username} = {
      programs = {
        ssh = {
          enable = true;

          matchBlocks = {
            "jezrien taln tanavast taldain" = {
              forwardAgent = true;
              extraOptions = { "IdentityAgent" = "~/.1password/agent.sock"; };
            };

            "quadra" = { user = "quadra"; };
            "pihole" = { user = username; };

            "github.com" = {
              extraOptions = { "IdentityAgent" = "~/.1password/agent.sock"; };
            };
          };
        };
      };
    };
  };
}
