{ config, inputs, lib, pkgs, hostname, username, ... }:
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
      # "personal"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
      # jezrien
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+urk8awyDQhOmONXIsAcHzaIlvHSiTD4rL/5GAHo6D"
      # taln
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuqj/tHToO+z85WFIkZ62Us4pvGW5sbHpIXC1zikNqs"
      # tanavast
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyLlKC6ACrukTYsLEdOQ7s9bi1i3Ncu6g+uPk1lxf0s"
      # taldain
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILXPP3eYU/t0j8PQpaXQMjbol9FUz/AaEDBkGkBGp9Ak"
    ];

    home-manager.users.${username} =
      let secretsPath = builtins.toString inputs.nix-secrets;
      in {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        home.packages = with pkgs; [ age sops ];

        sops = {
          defaultSopsFile = "${secretsPath}/${hostname}/secrets.yaml";
          age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
          secrets.ssh_private_key = {
            path = "/home/${username}/.ssh/id_ed25519";
          };
        };

        programs = {
          ssh = {
            enable = true;

            matchBlocks = {
              "jezrien taln tanavast taldain" = {
                forwardAgent = true;
                extraOptions = {
                  "IdentityAgent" = "~/.1password/agent.sock";
                  "IdentityFile" = "~/.ssh/id_ed25519";
                };
              };

              "github.com" = {
                extraOptions = { "IdentityAgent" = "~/.1password/agent.sock"; };
              };
            };
          };
        };
      };
  };
}
