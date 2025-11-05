{ ... }: {
  imports = [
    ./hyprland
    ./niri

    ./caelestia
    ./dank-material-shell
    ./noctalia

    ./gnome.nix
    ./kde.nix
    ./niri.nix
  ];
}

# TODO: replace desktop role with this more meta-style module
# options.rhx.desktop = {
#   environments = lib.mkOption {
#     type = lib.types.listOf (lib.types.submodule {
#       options = {
#         wm = lib.mkOption {
#           type = lib.types.listOf (lib.types.enum [ "hyprland" "niri" ]);
#           default = [ "hyprland" ];
#         };

#         bar = lib.mkOption {
#           type = lib.types.enum [
#             "caelestia"
#             "dank-material-shell"
#             "noctalia"
#             "none"
#           ];
#           default = "none";
#         };
#       };
#     });
#     default = [{
#       wm = "hyprland";
#       bar = "caelestia";
#     }];
#   };

#   greeter = lib.mkOption {
#     type = lib.types.enum [ "dank-material-shell" ];
#     default = "dank-material-shell";
#   };
# };

# config = let
#   envs = cfg.environments;
#   isWmEnabled = env: lib.elem env envs.wm;

#   # mapMonitors = monitors: 
#   # desktopEnvs = cfg.desktopEnvironment;
#   # isEnabled = env: lib.elem env desktopEnvs;
# in {
#   rhx.hyprland = { enable = (isWmEnabled "hyprland"); };
#   rhx.niri = { enable = (isWmEnabled "niri"); };
#   # rhx.hyprland.enable = (isEnabled "hyprland");
#   # rhx.niri.enable = (isEnabled "niri");

#   programs.dankMaterialShell.greeter.enable = cfg.greeter
#     == "dank-material-shell";

#   home-manager.users.${username} = {
#     rhx.caelestia.enable = cfg.bar == "caelestia";
#     rhx.dank-material-shell.enable = cfg.bar == "caelestia";
#     rhx.noctalia.enable = cfg.bar == "noctalia";
#   };
# };
