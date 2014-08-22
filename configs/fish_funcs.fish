function steamcd 
  cd ~/.local/share/Steam/SteamApps/common
end

function nvsettings
  primusrun nvidia-settings -c :8 &
end

function steam_wine
  primusrun wine "/home/dusty/.wine32/drive_c/Program Files/Steam/Steam.exe" &
end

function pacman_deps
  pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'
end

### pacman stuff

function pacinstall --description "pacman -S"
  sudo pacman -S $argv
end

function pacquery --description "pacman -Qs"
  pacman -Qs $argv
end

function pacsearch --description "pacman -Ss"
  pacman -Ss $argv
end

function pacupdatemirrors
  sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist
end
