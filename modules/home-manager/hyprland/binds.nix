{ config, lib, ... }: {
  wayland.windowManager.hyprland.settings = let
    moveFocusCommand =
      if config.rhx.hyprland.hy3.enable then "hy3:movefocus" else "movefocus";
    moveWindowCommand =
      if config.rhx.hyprland.hy3.enable then "hy3:movewindow" else "movewindow";

    workspaces = config.rhx.hyprland.workspaces;
    workspaceBinds = lib.concatMap (i:
      let index = toString (i + 1);
      in [
        "$mainMod, ${index}, workspace, ${index}"
        "$mainMod SHIFT, ${index}, movetoworkspace, ${index}"
      ]) (lib.lists.range 0 ((lib.lists.length workspaces) - 1));
  in {
    bind = [
      "$mainMod, Return, exec, $terminal"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, C, exec, ~/.dotfiles/configs/hypr/scripts/conditional-killactive.nu"
      "$mainMod SHIFT, C, killactive,"
      "$mainMod SHIFT, E, exec, wlogout"

      "$mainMod, R, exec, albert toggle"
      "$mainMod, space, exec, albert toggle"
      "$mainMod SHIFT, R, exec, fuzzel" # fallback

      "$mainMod, F, fullscreen"
      "$mainMod, V, togglefloating"

      "$mainMod, h, ${moveFocusCommand}, l"
      "$mainMod, j, ${moveFocusCommand}, d"
      "$mainMod, k, ${moveFocusCommand}, u"
      "$mainMod, l, ${moveFocusCommand}, r"
      "$mainMod SHIFT, h, ${moveWindowCommand}, l"
      "$mainMod SHIFT, j, ${moveWindowCommand}, d"
      "$mainMod SHIFT, k, ${moveWindowCommand}, u"
      "$mainMod SHIFT, l, ${moveWindowCommand}, r "

      "$mainMod, 0, togglespecialworkspace, special"
      "$mainMod SHIFT, 0, movetoworkspace, special"

      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"

      "$mainMod SHIFT, F1, exec, ~/.dotfiles/configs/hypr/scripts/hyprprop-notify.nu"
      ''$mainMod SHIFT, Print, exec, grim -g "$(slurp)" - | swappy -f -''
      ''$mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy''
      "$mainMod SHIFT, V, exec, cliphist list | wofi --show dmenu"

      "$mainMod, g, exec, ~/.dotfiles/configs/nu/scripts/toggle-eve.nu"

      ", XF86AudioMute, exec, amixer sset Master toggle"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
      ''
        , XF86MonBrightnessUp, exec, xbacklight +5 && notify-send "Brightness - $(xbacklight -get | cut -d '.' -f 1)%"''
      ''
        , XF86MonBrightnessDown, exec, xbacklight -5 && notify-send "Brightness - $(xbacklight -get | cut -d '.' -f 1)%"''
    ] ++ workspaceBinds ++ (lib.optionals config.rhx.hyprland.hy3.enable [
      # "$mainMod, ???, hy3:changegroup, opposite"
    ]);

    binde = [
      ", XF86AudioRaiseVolume, exec, amixer sset Master 5%+"
      ", XF86AudioLowerVolume, exec, amixer sset Master 5%-"
    ];

    bindm =
      [ "$mainMod, mouse:272, movewindow" "$mainMod, mouse:273, resizewindow" ];
  };
}
