# Plain list, not a module: both the installed system and the installer ISO
# need these, and the ISO is built from its own `nixosSystem`.
#
# Deliberately NOT Dusty's personal/jezrien/taln keys. This is a single
# dedicated admin keypair used nowhere else; its private half stays on the
# operator's machine at `~/.config/elantris/admin_ed25519`, outside this
# repo and outside the guest. See [[OpenRig Agent World]] in Arcanum.
[
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3c6vStLBIvEePf8tb1GAvHEeOsfiMZ1I/jJsjZ21mo elantris-admin"
]
