{
  _1password = import ./1password.nix;
  base = import ./base.nix;
  btrfs = import ./btrfs.nix;
  budgie = import ./budgie.nix;
  docker = import ./docker.nix;
  gaming = import ./gaming.nix;
  gnome = import ./gnome.nix;
  hyprland = import ./hyprland.nix;
  keebs = import ./keebs.nix;
  libvirtd = import ./libvirtd.nix;
  pipewire = import ./pipewire.nix;
  rust = import ./rust.nix;
  ssh = import ./ssh.nix;
}
