{ config, lib, username, pkgs, ... }:
let cfg = config.rhx.ssh;
in {
  options.rhx.ssh.enable = lib.mkEnableOption "Enable ssh nixOS module";

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
  };
}
