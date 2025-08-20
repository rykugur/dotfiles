{ ... }: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
      "1password"
      "albert"
      "discord"
      "steam"
      "playerctld daemon"
      "wl-paste --watch cliphist store"
      "solaar -w hide"
      "corectrl --minimize-systray"
    ];
  };
}
