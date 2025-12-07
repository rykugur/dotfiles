let pfxDir = $"($env.HOME)/.local/share/Steam/steamapps/compatdata/8500/pfx"
let ccpSettingsDir = (
  if (is-linux) {
    $"($env.HOME)/.local/share/Steam/steamapps/compatdata/8500/pfx/drive_c/users/steamuser/AppData/Local/CCP/EVE/c_ccp_eve_tq_tranquility"
  } else {
    $"($env.HOME)/Library/Application Support/CCP/EVE/_users_($env.USER)_library_application_support_eve_online_sharedcache_tq_eve.app_contents_resources_build_tranquility"
  }
)
let piTemplatesDir = (
  if (is-linux) {
    $"($pfxDir)/drive_c/users/steamuser/Documents/EVE/PlanetaryInteractionTemplates"
  }
  else {
    $"($env.HOME)/Documents/EVE/PlanetaryInteractionTemplates"
  }
)
let gitSettingsDir = $"($env.HOME)/gits/eve-settings"

def --env "eve pfx" [] {
  use std/log
  if (not (is-linux)) {
    log error "This command is linux-only, doing nothing."
    return
  }
  cd $pfxDir
}

def --env "eve settings" [] {
  cd $ccpSettingsDir
}

def --env "eve pi templates" [] {
  cd $piTemplatesDir
}

def --env "eve gits" [] {
  cd $gitSettingsDir
}

def "eve EANM" [] {
  let _hostname = (hostname | str replace ".local" "")
  let dir = $gitSettingsDir
  cd $"($dir)/($_hostname)"; nix run nixpkgs#zulu -- -jar $"($dir)/EANM.jar"
}

def "eve CustomShipLabeler" [] {
  nix run nixpkgs#zulu24 -- -jar $"($gitSettingsDir)/EVE_CustomShipLabelerV1.jar"
}

def "eve pi get name" [] {
  let json = $in
  $json | get Cmt | str replace ' ' '' --all
}
