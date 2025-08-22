{ ... }: {
  wayland.windowManager.hyprland.settings = {
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

      "$mainMod, h, hy3:movefocus, l"
      "$mainMod, j, hy3:movefocus, d"
      "$mainMod, k, hy3:movefocus, u"
      "$mainMod, l, hy3:movefocus, r"
      "$mainMod SHIFT, h, hy3:movewindow, l"
      "$mainMod SHIFT, j, hy3:movewindow, d"
      "$mainMod SHIFT, k, hy3:movewindow, u"
      "$mainMod SHIFT, l, hy3:movewindow, r "

      # TODO: would be nice to make this dynamic based on the length of the workspace list.
      # "$mainMod, 1, workspace, 1"
      # "$mainMod, 2, workspace, 2"
      # "$mainMod, 3, workspace, 3"
      # "$mainMod, 4, workspace, 4"
      # "$mainMod, 5, workspace, 5"
      # "$mainMod SHIFT, 1, movetoworkspace, 1"
      # "$mainMod SHIFT, 2, movetoworkspace, 2"
      # "$mainMod SHIFT, 3, movetoworkspace, 3"
      # "$mainMod SHIFT, 4, movetoworkspace, 4"
      # "$mainMod SHIFT, 5, movetoworkspace, 5"

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
    ];

    binde = [
      ", XF86AudioRaiseVolume, exec, amixer sset Master 5%+"
      ", XF86AudioLowerVolume, exec, amixer sset Master 5%-"
    ];

    bindm =
      [ "$mainMod, mouse:272, movewindow" "$mainMod, mouse:273, resizewindow" ];
  };
}
