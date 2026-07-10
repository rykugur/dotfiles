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

        # fish registers itself via programs.fish below; others need explicit /etc/shells entry.
        environment.shells = lib.mkIf (cfg != "fish") [ shellPkg ];

        programs.fish.enable = lib.mkIf (cfg == "fish") true;
      };
    };
}
