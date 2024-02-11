# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  firefox = import ./firefox.nix;
  fish = import ./fish.nix;
  gaming = import ./gaming.nix;
  git = import ./git.nix;
  gnome = import ./gnome.nix;
  kitty = import ./kitty.nix;
  hyprland = import ./hyprland.nix;
  nvidia = import ./nvidia.nix;
  nvim = import ./nvim.nix;
  obs = import ./obs.nix;
  star-citizen = import ./star-citizen.nix;
  terminal = import ./terminal.nix;
  theme = import ./theme.nix;
}
