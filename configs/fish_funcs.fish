function steamcd 
  cd ~/.local/share/Steam/SteamApps/common
end

function nvsettings
  primusrun nvidia-settings -c :8 &
end

function steam_wine
  primusrun "/home/dusty/.wine32/drive_c/Program Files/Steam/Steam.exe" &
end

function pacman_deps
  pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'
end

function update_pacman_mirrors
  sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist
end
