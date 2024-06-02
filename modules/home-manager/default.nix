# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  # firefox = import ./firefox.nix;
  # git = import ./git.nix;
  #
  # gbar = import ./gbar.nix;
  # gnome = import ./gnome.nix;
  # hyprland = import ./hyprland.nix;
  # theme = import ./theme.nix;
  # swayfx = import ./swayfx.nix;
  # wayland = import ./wayland.nix;
  #
  # fish = import ./fish.nix;
  # kitty = import ./kitty.nix;
  # nvim = import ./nvim.nix;
  # starship = import ./starship.nix;
  # terminal = import ./terminal.nix;
  # tmux = import ./tmux.nix;
  #
  # face-tracking = import ./face-tracking.nix;
  # gaming = import ./gaming.nix;
  # obs = import ./obs.nix;
  # starcitizen = import ./starcitizen.nix;
  # starsector = import ./starsector.nix;

  imports = [
    ./firefox.nix
    ./git.nix
    ./swappy.nix

    ./gbar.nix
    ./gnome.nix
    # ./hyprland.nix
    ./theme.nix
    ./swayfx.nix
    ./wayland.nix

    ./fish.nix
    ./kitty.nix
    ./nvim.nix
    ./starship.nix
    ./terminal.nix
    ./tmux.nix

    ./face-tracking.nix
    ./gaming.nix
    # ./starcitizen.nix
    ./starsector.nix
  ];
}
