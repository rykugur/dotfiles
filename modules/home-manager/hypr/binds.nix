{
  "$mainMod" = "SUPER";
  bind = [
    "$mainMod, Return, exec, $terminal"
    "$mainMod, E, exec, thunar"
    "$mainMod, C, killactive, "
    "$mainMod SHIFT, E, exec, wlogout"
    "$mainMod, F, fullscreen"
    "$mainMod, V, togglefloating "
    "$mainMod, R, exec, albert toggle"
    # fallback beacuse once albert was borked
    "$mainMod SHIFT, R, exec, fuzzel"
    "$mainMod, space, exec, albert toggle"
    "$mainMod, P, pseudo, # dwindle"

    "$mainMod, h, movefocus, l"
    "$mainMod, j, movefocus, d"
    "$mainMod, k, movefocus, u"
    "$mainMod, l, movefocus, r"
    "$mainMod SHIFT, h, movewindow, l"
    "$mainMod SHIFT, j, movewindow, d"
    "$mainMod SHIFT, k, movewindow, u"
    "$mainMod SHIFT, l, movewindow, r "

    # Switch workspaces with mainMod + [0-9]
    "$mainMod, 1, workspace, 1"
    "$mainMod, 2, workspace, 2"
    "$mainMod, 3, workspace, 3"
    "$mainMod, 4, workspace, 4"
    "$mainMod, 5, workspace, 5"
    "$mainMod, 6, workspace, 6"
    "$mainMod, 7, workspace, 7"

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    "$mainMod SHIFT, 1, movetoworkspace, 1"
    "$mainMod SHIFT, 2, movetoworkspace, 2"
    "$mainMod SHIFT, 3, movetoworkspace, 3"
    "$mainMod SHIFT, 4, movetoworkspace, 4"
    "$mainMod SHIFT, 5, movetoworkspace, 5"
    "$mainMod SHIFT, 6, movetoworkspace, 6"
    "$mainMod SHIFT, 7, movetoworkspace, 7"

    # Example special workspace (scratchpad)
    "$mainMod, 0, togglespecialworkspace, magic"
    "$mainMod SHIFT, 0, movetoworkspace, special:magic"

    # Scroll through existing workspaces with mainMod + scroll
    "$mainMod, mouse_down, workspace, e+1"
    "$mainMod, mouse_up, workspace, e-1"

    ", XF86AudioMute, exec, amixer sset Master toggle"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPause, exec, playerctl play-pause"
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPrev, exec, playerctl previous"
    # ''
    #   XF86MonBrightnessUp, exec, xbacklight +5 && notify-send "Brightness - $(xbacklight -get | cut -d '.' -f 1)%"''
    # ''
    #   XF86MonBrightnessDown, exec, xbacklight -5 && notify-send "Brightness - $(xbacklight -get | cut -d '.' -f 1)%"''

    # Misc binds
    "$mainMod SHIFT, F1, exec, hyprprop | jq '.class' | wl-copy"
    ''mainMod SHIFT, Print, exec, grim -g "$(slurp)" - | swappy -f -''
    ''mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy''
    "$mainMod SHIFT, V, exec, cliphist list | wofi --show dmenu"
  ];

  binde = [
    ", XF86AudioRaiseVolume, exec, amixer sset Master 5%+"
    ", XF86AudioLowerVolume, exec, amixer sset Master 5%-"
  ];
  bindm = [
    # Move/resize windows with mainMod + LMB/RMB and dragging
    "$mainMod, mouse:272, movewindow"
    "$mainMod, mouse:273, resizewindow"
  ];
}
