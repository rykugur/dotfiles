#

function dpass --description 'easy wrapper that allows dmenu to use pass'
  set -l _PASSWORD_STORE "$HOME/.password-store"
  if test ! -e $_PASSWORD_STORE
    /usr/bin/notify-send "no password store found"
  end # end if

  # TODO: find a way to not hard-code the path in sed... doesn't work so well in fish
  set -l _CHOSEN_ACCT (find $_PASSWORD_STORE -type f -name "*.gpg" | sed s/"\/home\/dusty\/.password-store\/"//g | sed s/.gpg//g | dmenu)

  echo (pass show $_CHOSEN_ACCT) | xclip -selection primary
end # end function
