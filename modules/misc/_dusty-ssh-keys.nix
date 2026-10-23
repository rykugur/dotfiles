# Single source for Dusty's personal/jezrien/taln SSH public keys. Hosts
# import this directly (e.g. `import ../../misc/dusty-ssh-keys.nix`) so
# rotating a key only needs one edit here. Plain list, not a flake module:
# no specialArgs needed to use it, works from a nixosSystem's own installer
# definition too.
[
  # personal
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
  # jezrien
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+urk8awyDQhOmONXIsAcHzaIlvHSiTD4rL/5GAHo6D"
  # taln
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKORtO51gYjGRuP3pP/paOe8NcBfQvrcZLSSwc4bqpT"
]
