{ config, ... }:
let
  niriActions = config.lib.niri.actions or null;
  niriSpawn = niriActions.spawn or null;
in {
  launcher = {
    hyprland = {
      keybinds = [ "$mainMod, R" "$mainMod, space" ];
      action = "exec, albert toggle";
    };
    niri = {
      keybinds = [ "Mod+r" "Mod+Space" ];
      action = niriSpawn [ "albert" "toggle" ];
    };
  };
  screenshot = {
    hyprland = {
      keybinds = [ "$mainMod, Print" ];
      action = ''exec, grim -g "$(slurp)" - | wl-copy'';
    };
    niri = {
      keybinds = [ "Mod+Print" ];
      action.spawn = niriSpawn [ ];
    };
  };
}
