let stalker2AppId = "1643320"
let stalker2GameName = "S.T.A.L.K.E.R. 2 Heart of Chornobyl"
let stalker2CompatDataPath = $"($env.HOME)/.local/share/Steam/steamapps/compatdata/($stalker2AppId)"
let stalker2InstallPath = $"($env.HOME)/.local/share/Steam/steamapps/common/($stalker2GameName)"

def --env "stalker2 pfx" [] {
  cd $stalker2CompatDataPath
}

def --env "stalker2 cd" [] {
  cd $stalker2InstallPath
}

def --env "stalker2 mods" [] {
  cd $"($stalker2InstallPath)/Stalker2/Content/Paks/~mods"
}
