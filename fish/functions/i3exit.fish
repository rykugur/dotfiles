#

function i3exit --description 'script to control locking, suspend, etc. in i3'
  if test (count $argv) -ge 1
    set -l ctl $argv[1]
    switch $ctl
      case lock
        #i3lock -c 000000
        slock
      case logout
        i3-msg exit
      case suspend
        #i3lock -c 000000; systemctl suspend
        slock &
        systemctl suspend
      case hibernate
        #i3lock -c 000000; systemctl hibernate
        slock &
        systemctl hibernate
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
