{ ... }:
{
  flake.modules.nixos.login-shell =
    { config, lib, pkgs, ... }:
    let
      cfg = config.ryk.defaultShell;
      shellPkg = {
        fish = pkgs.fish;
        nushell = pkgs.nushell;
        bash = pkgs.bashInteractive;
      }.${cfg};
    in
    {
      options.ryk.defaultShell = lib.mkOption {
        type = lib.types.enum [ "fish" "nushell" "bash" ];
        default = "nushell";
        description = "Login shell and shell used everywhere for the primary user.";
      };

      config = {
        users.users.${config.ryk.username}.shell = shellPkg;

        # Make the chosen shell a valid login shell (/etc/shells).
        environment.shells = [ shellPkg ];

        # fish's NixOS module wires completions + /etc/shells + system integration.
        programs.fish.enable = lib.mkIf (cfg == "fish") true;
      };
    };
}
