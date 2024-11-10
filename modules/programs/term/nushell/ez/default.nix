let
  dev_ez = import ./dev.nix;
  docker_ez = import ./docker.nix;
  git_ez = import ./git.nix;
  linux_ez = import ./linux.nix;
  misc_ez = import ./misc.nix;
  nixos_ez = import ./nixos.nix;
in {
  abbreviations = dev_ez.abbreviations // docker_ez.abbreviations
    // git_ez.abbreviations // linux_ez.abbreviations // misc_ez.abbreviations
    // nixos_ez.abbreviations;
  aliases = dev_ez.aliases // docker_ez.aliases // git_ez.aliases
    // linux_ez.aliases // misc_ez.aliases // nixos_ez.aliases;
  env = dev_ez.env // docker_ez.env // git_ez.env // linux_ez.env // misc_ez.env
    // nixos_ez.env;
}
