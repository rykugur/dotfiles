{ pkgs, ... }: {
  home.packages = with pkgs; [
    cliphist
    pywal
    wev
    wl-clipboard
    wl-clipboard-x11
    wofi
    wofi-emoji
    wtype
    xorg.xrandr
    xorg.xbacklight
  ];
}
