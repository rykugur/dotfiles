#

function i3exit --description 'script to control locking, suspend, etc. in i3'
  if test -e $HOME/bin/pixellock
    set _LOCK "$HOME/bin/pixellock"
  else 
    notify-send "pixellock script missing, defaulting to i3lock"
    set _LOCK "i3lock"
  end

  if test (count $argv) -ge 1
    set -l ctl $argv[1]
    switch $ctl
      case lock
        eval $_LOCK &
      case logout
        i3-msg exit
      case suspend
        systemctl suspend
        eval $_LOCK &
      case hibernate
        systemctl hibernate
        eval $_LOCK &
      case reboot
        systemctl reboot
      case shutdown
        systemctl poweroff
      case '*'
        echo "Usage: $0 {lock|logout|suspend|hibernate|reboot|shutdown}"
        exit 2
    end
  end
end
