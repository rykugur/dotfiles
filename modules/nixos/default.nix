# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  _1password = import ./1password.nix;
  base = import ./base.nix;
  btrfs = import ./btrfs.nix;
  docker = import ./docker.nix;
  gaming = import ./gaming.nix;
  gnome = import ./gnome.nix;
  hyprland = import ./hyprland.nix;
  pipewire = import ./pipewire.nix;
  rust = import ./rust.nix;
  ssh = import ./ssh.nix;
}
