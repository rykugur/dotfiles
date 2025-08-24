{ config, lib, ... }: {
  wayland.windowManager.hyprland.settings = {
    exec = [ ] ++ (lib.optionals config.rhx.hyprland.waybar.enable
      [ "pkill -SIGUSR2 waybar || waybar" ]);

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
    # ++ (lib.optionals config.rhx.hyprland.quickshell.enable
    #   [ "caelestia-shell -d" ]);
  };
}
