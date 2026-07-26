# SSH access baseline shared by the bootstrap seed image (_seed.nix) and the
# managed host role (_role.nix). Scope is deliberately narrow: sshd itself, the
# authentication policy needed to reach the box at all, and the operator key.
# Anything that only one of the two needs stays in that file.
{ ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Personal key, mirrors modules/misc/ssh.nix; keep in sync if rotated.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
  ];
}
