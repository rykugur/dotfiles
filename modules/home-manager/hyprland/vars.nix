{ lib, ... }: {
  wayland.windowManager.hyprland.settings = {
    env = [
      "XDG_SESSION_TYPE,wayland"
      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_DESKTOP,Hyprland"
      "QT_QPA_PLATFORM,wayland"
      "QT_QPA_PLATFORMTHEME,qt5ct # change to qt6ct if you have that"
      "COPYCMD,wl-copy"
      "PASTECMD,wl-paste"
    ];

    "$mainMod" = lib.mkDefault "SUPER";
    "$terminal" = lib.mkDefault "ghostty --gtk-single-instance=true";
    "$browser" = lib.mkDefault "zen";
    "$fileManager" = lib.mkDefault "nautilus --new-window";
    "$music" = lib.mkDefault "spotify";
    "$passwordManager" = lib.mkDefault "1password";
    "$messenger" = lib.mkDefault "signal-desktop";
    "$webapp" = lib.mkDefault "$browser --app";

    "$discordWorkspace" = lib.mkDefault 4;
    "$steamWorkspace" = lib.mkDefault 4;
    "$gamingWorkspace" = lib.mkDefault 3;
  };
}
