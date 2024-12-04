{
  # set some env variables
  env = [
    "XDG_SESSION_TYPE,wayland"
    "XDG_CURRENT_DESKTOP,Hyprland"
    "XDG_SESSION_DESKTOP,Hyprland"

    "QT_QPA_PLATFORM,wayland"
    "QT_QPA_PLATFORMTHEME,qt5ct" # change to qt6ct if you have that

    "COPYCMD,wl-copy"
    "PASTECMD,wl-paste"
  ];
  "$terminal" = "kitty";
  "$fileManager" = "nemo";
  "$menu" = "fuzzel";
  "exec-once" = [
    "1password"
    "albert"
    "ags"
    "discord"
    #"steam"
    "dunst"
    "playerctld daemon"
    "wl-paste --watch cliphist store"
  ];
  general = {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    "gaps_in" = 5;
    "gaps_out" = 20;
    "border_size" = 2;
    "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
    "col.inactive_border" = "rgba(595959aa)";
    layout = "dwindle";
    # layout = "hy3";
    # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
    allow_tearing = false;
  };
  misc = { "disable_hyprland_logo" = true; };
  decoration = {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more

    rounding = 10;

    blur = {
      enabled = true;
      size = 3;
      passes = 1;
    };

    drop_shadow = "yes";
    shadow_range = 4;
    shadow_render_power = 3;
    "col.shadow" = "rgba(1a1a1aee)";
  };
  animations = {
    enabled = true;
    first_launch_animation = true;
    bezier = [
      "wind, 0.05, 0.9, 0.1, 1.05"
      "winIn, 0.1, 1.1, 0.1, 1.1"
      "winOut, 0.3, -0.3, 0, 1"
      "liner, 1, 1, 1, 1"
    ];
    animation = [
      "windows, 1, 6, wind, slide"
      "windowsIn, 1, 6, winIn, slide"
      "windowsOut, 1, 5, winOut, slide"
      "windowsMove, 1, 5, wind, slide"
      "border, 1, 1, liner"
      "borderangle, 1, 30, liner, loop"
      "fade, 1, 10, default"
      "workspaces, 1, 5, wind"
    ];

  };
  dwindle = {
    pseudotile =
      "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = "yes"; # you probably want this
    force_split = 2;

  };
  # master = {
  #   # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
  #   new_is_master = false;
  # };
  windowrulev2 = [
    "float, class:(1Password)"
    "float, class:(com.github.iwalton3.jellyfin-media-player)"
    "float, class:(com.obsproject.Studio)"
    "float, class:(galculator)"
    "float, class:(neovide)"
    "float, class:(nemo)"
    "float, class:(thunar)"
    "float, class:(pavucontrol)"
    "float, class:(ristretto) # image viewer"
    "float, class:(Spotify)"
    "float, class:(virt-manager)"
    "float, class:(vlc)"
    "float, class:(yad)"
    "float, class:(zenity)"
  ];
  input = {
    kb_layout = "";
    kb_variant = "";
    kb_model = "";
    kb_options = "";
    kb_rules = "";

    follow_mouse = 2;
    # fixes oddities with drop-down menu items, e.g. steam
    mouse_refocus = false;

    touchpad = {
      natural_scroll = "no";
      tap-to-click = true;
      clickfinger_behavior = true;
    };

    sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

    repeat_rate = 60;
    repeat_delay = 200;
  };
  gestures = {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    workspace_swipe = true;
    workspace_swipe_fingers = 3;
    workspace_swipe_invert = false;
  };
}
