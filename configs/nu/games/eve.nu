$env.eve-online = {
  PFX_DIR: $"($env.HOME)/.local/share/Steam/steamapps/compatdata/8500/pfx",
  CCP_SETTINGS_DIR: (
    if (is-linux) {
      $"($env.HOME)/.local/share/Steam/steamapps/compatdata/8500/pfx/drive_c/users/steamuser/AppData/Local/CCP/EVE/c_ccp_eve_tq_tranquility"
    } else {
      $"($env.HOME)/Library/Application Support/CCP/EVE/_users_($env.USER)_library_application_support_eve_online_sharedcache_tq_eve.app_contents_resources_build_tranquility"
    }
  ),
  PI_TEMPLATES_DIR: $"($env.HOME)/Documents/EVE/PlanetaryInteractionTemplates",
  GIT_SETTINGS_DIR: $"($env.HOME)/gits/eve-settings"
}

def --env "eve pfx" [] {
  use std/log
  if (not (is-linux)) {
    log error "This command is linux-only, doing nothing."
    return
  }
  cd $"($env.eve-online.PFX_DIR)"
}

def --env "eve settings" [] {
  cd $env.eve-online.CCP_SETTINGS_DIR
}

def --env "eve pi tempaltes" [] {
  cd $env.eve-online.PI_TEMPLATES_DIR
}

def --env "eve gits" [] {
  cd $env.eve-online.GIT_SETTINGS_DIR
}

def "eve eanm" [] {
  let _hostname = (hostname | str replace ".local" "")
  let dir = $"($env.HOME)/gits/eve-settings"
  cd $"($dir)/($_hostname)"; nix run nixpkgs#zulu -- -jar $"($dir)/EANM.jar"
}
