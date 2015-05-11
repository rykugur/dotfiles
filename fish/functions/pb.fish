#

function pb --description "pianobar wrapper for awesomeness"
  set -l _pandora_un (cat ~/.pandorapass | cut -d':' -f1)
  set -l _pandora_pass (cat ~/.pandorapass | cut -d':' -f2)

  set -l _pianobar_cmd "
    spawn pianobar
    set timeout 0.001
    expect \"\[?\] Email:\"
    send \"$_pandora_un\n\"
    expect \"\[?\] Password:\"
    send \"$_pandora_pass\n\"
    interact"

  expect -c $_pianobar_cmd
end
