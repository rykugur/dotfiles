# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  browser = import ./browser.nix;
  face-tracking = import ./face-tracking.nix;
  fish = import ./fish.nix;
  gaming = import ./gaming.nix;
  git = import ./git.nix;
  gnome = import ./gnome.nix;
  kitty = import ./kitty.nix;
  hyprland = import ./hyprland.nix;
  nvim = import ./nvim.nix;
  obs = import ./obs.nix;
  starcitizen = import ./starcitizen.nix;
  starsector = import ./starsector.nix;
  starship = import ./starship.nix;
  terminal = import ./terminal.nix;
  theme = import ./theme.nix;
  tmux = import ./tmux.nix;
  wayland = import ./wayland.nix;
}
