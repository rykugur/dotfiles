{ config, inputs, lib, pkgs, username, ... }:
let
  cfg = config.rhx.hyprland;
  barNames = (import ../shared.nix).bars;
in {
  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland module.";

    bar = lib.mkOption {
      type = lib.types.enum barNames;
      default = "none";
    };

    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Monitors to define.";
    };

    useDynamicWorkspaces = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "If true, workspaces will not be pre-defined.";
    };

    workspaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "1" "2" "3" ];
      description = "Workspaces to define.";
    };

    layout = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "master" "hy3" "scrolling" ]);
      default = null;
      description = "Which layout to use.";
    };

    # hy3.enable = lib.mkOption {
    #   type = lib.types.bool;
    #   default = false;
    #   description = "Enable hy3 plugin for i3 like tiling.";
    # };

    # hyprscrolling.enable = lib.mkOption {
    #   type = lib.types.bool;
    #   default = false;
    #   description =
    #     "Enable hyprscrolling plugin (for niri/PaperWM-like scrolling workspaces).";
    # };

    hypridle.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable hypridle";
    };

    hyprlock.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable hyprlock";
    };
  };

  config = let isBarEnabled = bar: cfg.bar == bar;
  in lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      xwayland.enable = true;
    };

    xdg.portal = { enable = true; };

    # rhx.caelestia.enable = (isBarEnabled "caelestia");
    rhx.dankMaterialShell.enable = (isBarEnabled "dankMaterialShell");
    rhx.noctalia.enable = (isBarEnabled "noctalia");

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
