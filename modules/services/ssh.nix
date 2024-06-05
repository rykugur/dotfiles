{
  config,
  lib,
  username,
  ...
}: let
  cfg = config.services.ssh;
in {
  options = {
    services.ssh.enable = lib.mkEnableOption "Enable SSH.";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
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
            "jezrien taln tanavast" = {
              forwardAgent = true;
              extraOptions = {
                "IdentityAgent" = "~/.1password/agent.sock";
              };
            };

            "quadra" = {
              user = "quadra";
            };
            "github.com" = {
              extraOptions = {
                "IdentityAgent" = "~/.1password/agent.sock";
              };
            };
          };
        };
      };
    };
  };
}
