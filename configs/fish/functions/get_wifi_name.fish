#

function get_wifi_name --description "Gets the SSID of the currently connected wifi, if there is one"
  set -l argc (count $argv)

  set -l _ssid ""
  set -l _arch (uname)
  if test $_arch = "Darwin"
    set _ssid (/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/ {print substr($0, index($0, $2))}')
  else if test $_arch = "Linux"
    # TODO
    return 1
  end

  if test -n $_ssid
    echo $_ssid
  else
    return 1
  end
end
