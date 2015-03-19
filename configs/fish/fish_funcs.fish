function nvsettings
  primusrun nvidia-settings -c :8 &
end

function steam_wine
  primusrun env WINEPREFIX=/home/dusty/.local/share/wineprefixes/steam WINEARCH=win32 wine "/home/dusty/.local/share/wineprefixes/steam/drive_c/Program Files/Steam/Steam.exe" &
  #primusrun env WINEPREFIX=/home/dusty/.wine32 WINEARCH=win32 wine "/home/dusty/.wine32/drive_c/Program Files/Steam/Steam.exe" &
end

function origin
  primusrun env WINEPREFIX=/home/dusty/.local/share/wineprefixes/origin WINEARCH=win32 wine "/home/dusty/.local/share/wineprefixes/origin/drive_c/Program Files/Origin/Origin.exe" &
end
