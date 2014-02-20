#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

sudo VBoxClient-all &

xrdb -merge ~/.Xresources
xrdb ~/.Xresources

xset r rate 200 25

#exec startxfce4
#exec enlightenment_start
exec i3
# ...or the Window Manager of your choice
